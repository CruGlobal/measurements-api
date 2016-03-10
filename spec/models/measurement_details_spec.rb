require 'rails_helper'

RSpec.describe MeasurementDetails, type: :model do
  let(:user) { FactoryGirl.create(:person) }
  let(:ministry) { FactoryGirl.create(:ministry) }

  def measurement_json(related_entity_id = nil)
    {
      measurement_type: {
        perm_link: 'LMI',
        measurements: [
          {
            id: SecureRandom.uuid, period: Time.zone.today.strftime('%Y-%m'),
            value: '3.0', related_entity_id: related_entity_id, dimension: 'DS_asdf'
          },
          {
            id: SecureRandom.uuid, period: (Time.zone.today - 1.month).strftime('%Y-%m'),
            value: '1.0', related_entity_id: related_entity_id
          }
        ]
      }
    }
  end

  def stub_measurement_type_gr(type_id, related_entity_id)
    WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{type_id}")
           .with(query: hash_including)
           .to_return(body: measurement_json(related_entity_id).to_json)
  end

  describe '#new' do
    let(:list) { MeasurementDetails.new }

    it 'has default values' do
      expect(list.period).to eq Time.zone.today.strftime('%Y-%m')
    end
  end

  describe '#load' do
    def stub_measurement_gr_calls(measurement = nil)
      measurement ||= meas

      stub_measurement_type_gr(measurement.total_id, ministry.gr_id)
      stub_measurement_type_gr(measurement.local_id, ministry.gr_id)
      stub_measurement_type_gr(measurement.person_id, user.gr_id)
    end

    before do
      stub_measurement_gr_calls
    end

    let(:meas) { FactoryGirl.create(:measurement, perm_link: 'lmi_total_custom_shown', mcc_filter: nil) }
    let(:details) { MeasurementDetails.new(id: meas.total_id, ministry_id: ministry.gr_id, mcc: 'DS') }

    it 'loads the total GR values' do
      details.load
      expect(details.total).to be_a Hash
      expect(details.total[Time.zone.today.strftime('%Y-%m')]).to eq 3
    end

    it 'loads the local breakdown' do
      details.load
      expect(details.local_breakdown).to be_a Hash
      expect(details.local_breakdown['total']).to eq 3
      expect(details.local_breakdown['asdf']).to eq 3
    end

    it 'loads the local monthly values' do
      details.load
      expect(details.local).to be_a Hash
      expect(details.local[Time.zone.today.strftime('%Y-%m')]).to eq 3
    end

    it 'loads self_breakdown' do
      FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :leader)
      Power.with_power(Power.new(user, ministry)) do
        details.load
      end
      expect(details.self_breakdown).to be_a Hash
      expect(details.self_breakdown['total']).to eq 3
    end
    it 'loads my_measurements monthly values' do
      FactoryGirl.create(:assignment, person: user, ministry: ministry, role: :leader)
      Power.with_power(Power.new(user, ministry)) do
        details.load
      end
      expect(details.my_measurements).to be_a Hash
      expect(details.my_measurements[Time.zone.today.strftime('%Y-%m')]).to eq 3
    end

    it 'loads team'
    it 'loads self_assigned'
    it 'loads split_measurements'
  end

  describe '#load_sub_mins_from_gr' do
    let(:meas) { FactoryGirl.create(:measurement, perm_link: 'lmi_total_custom_shown', mcc_filter: nil) }
    let(:details) { MeasurementDetails.new(id: meas.total_id, ministry_id: ministry.gr_id, mcc: 'DS') }

    it 'loads sub_ministries gr measurements' do
      child_min1 = FactoryGirl.create(:ministry, parent: ministry, name: 'something unique')
      FactoryGirl.create(:ministry, parent: ministry, name: 'another unique')
      stub_measurement_type_gr(meas.total_id, child_min1.gr_id)

      details.load_sub_mins_from_gr
      expect(details.sub_ministries.count).to be 2
      expect(details.sub_ministries.first[:name]).to eq child_min1.name
      expect(details.sub_ministries.first[:total]).to eq 4
      expect(details.sub_ministries.last[:total]).to eq 0
    end
  end
end
