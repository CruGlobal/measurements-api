# frozen_string_literal: true

require "rails_helper"

RSpec.describe MeasurementDetails, type: :model do
  let(:user) { FactoryBot.create(:person) }
  let(:ministry) { FactoryBot.create(:ministry) }

  def measurement_json(period_date, value, related_id, dimension = nil)
    {
      id: SecureRandom.uuid, period: period_date.strftime("%Y-%m"),
      value: value, related_entity_id: related_id, dimension: dimension,
    }
  end

  def measurements_json(related_entity_id = nil)
    {
      measurement_type: {
        perm_link: "LMI",
        measurements: [
          measurement_json(Time.zone.today, 3, related_entity_id, "DS"),
          measurement_json(Time.zone.today, 3, related_entity_id, "DS_asdf"),
          measurement_json(Time.zone.today - 1.month, 1, related_entity_id),
        ],
      },
    }
  end

  def stub_measurement_type_gr(type_id, related_entity_id)
    WebMock.stub_request(:get, "#{ENV["GLOBAL_REGISTRY_URL"]}/measurement_types/#{type_id}")
      .with(query: hash_including)
      .to_return(body: measurements_json(related_entity_id).to_json)
  end

  describe "#new" do
    it "has default values" do
      details = MeasurementDetails.new
      expect(details.period).to eq Time.zone.today.strftime("%Y-%m")
    end

    it "loads measurement by total_id" do
      meas = FactoryBot.create(:measurement)
      details = MeasurementDetails.new(id: meas.total_id)
      expect(details.measurement.id).to eq meas.id
    end

    it "loads measurement by perm_link" do
      meas = FactoryBot.create(:measurement, perm_link: "lmi_total_custom_shown")
      details = MeasurementDetails.new(id: "shown")
      expect(details.measurement.id).to eq meas.id
    end
  end

  describe "#load" do
    before do
      stub_measurement_type_gr(meas.total_id, ministry.gr_id)
      stub_measurement_type_gr(meas.local_id, ministry.gr_id)
      stub_measurement_type_gr(meas.person_id, user.gr_id)

      allow(details).to receive(:update_total_in_gr)
    end

    let(:meas) { FactoryBot.create(:measurement, perm_link: "lmi_total_custom_shown", mcc_filter: nil) }
    let(:details) { MeasurementDetails.new(id: meas.total_id, ministry_id: ministry.gr_id, mcc: "DS") }

    it "loads the total GR values" do
      details.load
      expect(details.total).to be_a Hash
      expect(details.total[Time.zone.today.strftime("%Y-%m")]).to eq 3
    end

    it "loads the local breakdown" do
      details.load
      expect(details.local_breakdown).to be_a Hash
      expect(details.local_breakdown["total"]).to eq 3
      expect(details.local_breakdown["asdf"]).to eq 3
    end

    it "loads the local monthly values" do
      details.load
      expect(details.local).to be_a Hash
      expect(details.local[Time.zone.today.strftime("%Y-%m")]).to eq 3
    end
  end

  describe "#load_user_from_gr" do
    let(:meas) { FactoryBot.create(:measurement, perm_link: "lmi_total_custom_shown", mcc_filter: nil) }
    let(:details) { MeasurementDetails.new(id: meas.total_id, ministry_id: ministry.gr_id, mcc: "DS") }
    let(:assignment) { FactoryBot.create(:assignment, person: user, ministry: ministry, role: :leader) }

    def measurements_json(related_entity_id = nil)
      {
        measurement_type: {
          perm_link: "LMI",
          measurements: [
            measurement_json(Time.zone.today, 3, related_entity_id, "DS_asdf"),
            measurement_json(Time.zone.today, 2, related_entity_id, "DS"),
            measurement_json(Time.zone.today - 1.month, 5, related_entity_id, "DS_asdf"),
            measurement_json(Time.zone.today - 1.month, 1, related_entity_id, "DS"),
          ],
        },
      }
    end

    before do
      stub_measurement_type_gr(meas.person_id, assignment.gr_id)
    end

    it "loads self_breakdown" do
      Power.with_power(Power.new(user, ministry)) do
        details.load_user_from_gr
      end
      expect(details.self_breakdown).to be_a Hash
      expect(details.self_breakdown["total"]).to eq 3
    end

    it "loads my_measurements monthly values" do
      Power.with_power(Power.new(user, ministry)) do
        details.load_user_from_gr
      end

      expect(details.my_measurements).to be_a Hash
      expect(details.my_measurements[Time.zone.today.strftime("%Y-%m")]).to eq 3
      expect(details.my_measurements[(Time.zone.today - 1.month).strftime("%Y-%m")]).to eq 1
    end
  end

  describe "#load_sub_mins_from_gr" do
    let(:meas) { FactoryBot.create(:measurement, perm_link: "lmi_total_custom_shown", mcc_filter: nil) }
    let(:details) { MeasurementDetails.new(id: meas.total_id, ministry_id: ministry.gr_id, mcc: "DS") }

    it "loads sub_ministries gr measurements" do
      child_min1 = FactoryBot.create(:ministry, parent: ministry, name: "something unique")
      FactoryBot.create(:ministry, parent: ministry, name: "another unique")
      stub_measurement_type_gr(meas.total_id, child_min1.gr_id)

      details.load_sub_mins_from_gr

      expect(details.sub_ministries.count).to be 2
      expect(details.sub_ministries.first[:name]).to eq child_min1.name
      expect(details.sub_ministries.first[:total]).to eq 3
      expect(details.sub_ministries.last[:total]).to eq 0
    end
  end

  describe "#load_team_members_from_gr" do
    let(:meas) { FactoryBot.create(:measurement, perm_link: "lmi_total_custom_shown", mcc_filter: nil) }
    let(:details) { MeasurementDetails.new(id: meas.total_id, ministry_id: ministry.gr_id, mcc: "DS") }

    def measurements_json(related_entity_id = nil)
      {
        measurement_type: {
          perm_link: "LMI",
          measurements: [
            measurement_json(Time.zone.today, 3, related_entity_id[0], "DS_asdf"),
            measurement_json(Time.zone.today, 2, related_entity_id[1], "DS_asdf"),
          ],
        },
      }
    end

    it "loads team members gr measurements" do
      teammate1 = FactoryBot.create(:person)
      teammate2 = FactoryBot.create(:person)
      team_assign1 = FactoryBot.create(:assignment, person: teammate1, ministry: ministry, role: :leader)
      team_assign2 = FactoryBot.create(:assignment, person: teammate2, ministry: ministry, role: :leader)
      stub_measurement_type_gr(meas.person_id, [team_assign1.gr_id, team_assign2.gr_id])

      details.load_team_from_gr
      subject = details.team

      expect(subject.count).to be 2
      expect(subject.first[:team_role]).to eq "leader"
      expect(subject.first[:total]).to eq 3
      expect(subject.last[:total]).to eq 2
    end

    it "does not include self in team" do
      FactoryBot.create(:assignment, person: user, ministry: ministry, role: :leader)
      teammate1 = FactoryBot.create(:person)
      team_assign1 = FactoryBot.create(:assignment, person: teammate1, ministry: ministry, role: :leader)
      stub_measurement_type_gr(meas.person_id, [team_assign1.gr_id])

      Power.with_power(Power.new(user, ministry)) do
        details.load_team_from_gr
      end
      subject = details.team

      expect(subject.count).to be 1
    end
  end

  describe "#load_split_measurements" do
    let(:meas) { FactoryBot.create(:measurement, perm_link: "lmi_total_custom_shown", mcc_filter: nil) }
    let(:details) { MeasurementDetails.new(id: meas.total_id, ministry_id: ministry.gr_id, mcc: "DS") }

    def measurements_json(related_entity_id = nil)
      {
        measurement_type: {
          perm_link: "LMI",
          measurements: [
            measurement_json(Time.zone.today, 3, related_entity_id, "DS_asdf"),
          ],
        },
      }
    end

    it "loads sub measurements gr measurements" do
      child1 = FactoryBot.create(:measurement, parent: meas, perm_link: "lmi_total_custom_asdf")
      child2 = FactoryBot.create(:measurement, parent: meas)
      stub_measurement_type_gr(child1.total_id, ministry.gr_id)
      stub_measurement_type_gr(child2.total_id, ministry.gr_id)

      details.load_split_measurements
      subject = details.split_measurements

      expect(subject.count).to be 2
      expect(subject["asdf"]).to be 3
    end
  end

  describe "#update_total_in_gr" do
    let(:meas) { FactoryBot.create(:measurement, perm_link: "lmi_total_custom_shown", mcc_filter: nil) }
    let(:details) { MeasurementDetails.new(id: meas.total_id, ministry_id: ministry.gr_id, mcc: "DS") }

    it "posts to GR if it has something new" do
      stub_measurement_type_gr(meas.total_id, ministry.gr_id)
      stub_measurement_type_gr(meas.local_id, ministry.gr_id)
      stub_measurement_type_gr(meas.person_id, user.gr_id)
      gr_update_stub = WebMock.stub_request(:post, "#{ENV["GLOBAL_REGISTRY_URL"]}/measurements")
        .to_return(status: 200, headers: {}, body: "{}")

      details.load_user_from_gr
      details.load_local_from_gr
      details.load_total_from_gr
      details.load_sub_mins_from_gr
      details.load_team_from_gr
      details.update_total_in_gr

      expect(gr_update_stub).to_not have_been_requested

      child1 = FactoryBot.create(:measurement, parent: meas, perm_link: "lmi_total_custom_asdf")
      stub_measurement_type_gr(child1.total_id, ministry.gr_id)

      details.load_split_measurements
      details.update_total_in_gr
      expect(gr_update_stub).to have_been_requested
    end
  end
end
