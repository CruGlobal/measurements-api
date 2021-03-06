# frozen_string_literal: true

require "rails_helper"

RSpec.describe MeasurementListReader, type: :model do
  let(:user) { FactoryBot.create(:person) }
  let(:ministry) { FactoryBot.create(:ministry) }

  describe "#new" do
    let(:list) { MeasurementListReader.new }

    it "has default values" do
      expect(list.period).to eq Time.zone.today.strftime("%Y-%m")
      expect(list.source).to eq "gma-app"
    end
  end

  describe "#load" do
    def measurement_json(related_entity_id = nil)
      {
        measurement_type: {
          perm_link: "LMI",
          measurements: [
            {
              id: SecureRandom.uuid, period: (Time.zone.today - 4.months).strftime("%Y-%m"),
              value: "3.0", related_entity_id: related_entity_id,
            },
            {
              id: SecureRandom.uuid, period: (Time.zone.today - 5.months).strftime("%Y-%m"),
              value: "1.0", related_entity_id: related_entity_id,
            },
          ],
        },
      }
    end

    def stub_measurement_gr_calls(measurement = nil)
      measurement ||= meas

      stub_measurement_type_gr(measurement.total_id, ministry.gr_id)
      stub_measurement_type_gr(measurement.local_id, ministry.gr_id)
      stub_measurement_type_gr(measurement.person_id, user.gr_id)
    end

    def stub_measurement_type_gr(type_id, related_entity_id)
      WebMock.stub_request(:get, "#{ENV["GLOBAL_REGISTRY_URL"]}/measurement_types/#{type_id}?")
        .with(query: hash_including)
        .to_return(body: measurement_json(related_entity_id).to_json)
    end

    before do
      stub_measurement_gr_calls
    end

    let(:meas) { FactoryBot.create(:measurement, perm_link: "lmi_total_test", mcc_filter: nil) }
    let(:list) { MeasurementListReader.new(ministry_id: ministry.gr_id, mcc: "DS") }

    it "returns Measurements" do
      expect(list.load.first).to be_a Measurement
    end

    it "loads the GR measurement values" do
      meas = list.load.first
      expect(meas.total).to eq 4
    end

    it "filters by mcc_filter" do
      FactoryBot.create(:measurement, mcc_filter: "SLM")

      expect(list.load.count).to be 1

      meas.update(mcc_filter: "DS")

      expect(list.load.count).to be 1
    end

    describe "filters by ministry hide_values and show_values" do
      it "shows default lmi with show/hide unset" do
        FactoryBot.create(:measurement, perm_link: "lmi_total_custom_not_shown")

        expect(list.load.count).to be 1
      end
      it "includes custom when set" do
        ministry.update(lmi_hide: ["hidden"], lmi_show: ["shown"])
        meas2 = FactoryBot.create(:measurement, perm_link: "lmi_total_hidden")
        FactoryBot.create(:measurement, perm_link: "lmi_total_custom_not_shown")

        expect(list.load.count).to be 1

        meas.update(perm_link: "lmi_total_not_hidden")
        meas2.update(perm_link: "lmi_total_custom_shown")
        stub_measurement_gr_calls(meas2)

        expect(list.load.count).to be 2
      end
    end

    describe "info based on assignment" do
      it "shows total to approved" do
        FactoryBot.create(:assignment, person: user, ministry: ministry, role: :admin)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.total).to_not be_nil
      end
      it "hides total from self-assigned" do
        FactoryBot.create(:assignment, person: user, ministry: ministry, role: :self_assigned)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.total).to be_nil
      end

      it "shows local to leaders" do
        parent_ministry = FactoryBot.create(:ministry)
        ministry.update(parent: parent_ministry)
        FactoryBot.create(:assignment, person: user, ministry: parent_ministry, role: :leader)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.local).to_not be_nil
      end
      it "hides local from members" do
        FactoryBot.create(:assignment, person: user, ministry: ministry, role: :member)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.local).to be_nil
      end

      it "shows personal to local" do
        FactoryBot.create(:assignment, person: user, ministry: ministry, role: :self_assigned)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.person).to_not be_nil
      end
      it "hides personal from inherited" do
        parent_ministry = FactoryBot.create(:ministry)
        ministry.update(parent: parent_ministry)
        FactoryBot.create(:assignment, person: user, ministry: parent_ministry, role: :leader)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.person).to be_nil
      end

      it "hides everything if blocked" do
        FactoryBot.create(:assignment, person: user, ministry: ministry, role: :blocked)
        Power.with_power(Power.new(user, ministry)) do
          @res = list.load
        end
        expect(@res.first.person).to be_nil
        expect(@res.first.local).to be_nil
        expect(@res.first.total).to be_nil
      end
    end

    it "loads historical data" do
      list.historical = true
      expect(list.load.first.total).to be_a Hash
      expect(list.load.first.total.count).to be 12
    end

    it "folds children in parents" do
      child_meas = FactoryBot.create(:measurement, parent: meas, perm_link: "lmi_total_asdf")
      stub_measurement_gr_calls(child_meas)

      resp = list.load

      expect(resp.count).to be 1
      expect(resp.first.loaded_children.count).to be 1
      expect(resp.first.loaded_children.first.person).to eq 4
    end
  end
end
