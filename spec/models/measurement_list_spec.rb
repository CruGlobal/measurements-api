require 'rails_helper'

RSpec.describe MeasurementList, type: :model do
  let(:user) { FactoryGirl.create(:person) }
  let(:ministry) { FactoryGirl.create(:ministry) }
  let(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }

  describe '#new' do
    let(:list) { MeasurementList.new }

    it 'has default values' do
      expect(list.period).to eq Time.zone.today.strftime('%Y-%m')
      expect(list.source).to eq 'gma-app'
    end
  end

  describe '#load' do
    def load
      assignment
      admin_power = Power.new(user, ministry)
      Power.with_power(admin_power) do
        list.load
      end
    end

    def measurement_json(related_entity_id)
      {
        measurement_type: {
          perm_link: 'LMI',
          measurements: [
            {
              id: SecureRandom.uuid,
              period: '2015-04',
              value: '4.0',
              related_entity_id: related_entity_id
            }
          ]
        }
      }
    end

    before do
      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{meas.total_id}?")
             .with(query: hash_including)
             .to_return(body: measurement_json(ministry.gr_id).to_json)
      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{meas.local_id}")
             .with(query: hash_including)
             .to_return(body: measurement_json(ministry.gr_id).to_json)
      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{meas.person_id}")
             .with(query: hash_including)
             .to_return(body: measurement_json(user.gr_id).to_json)
    end

    let(:meas) { FactoryGirl.create(:measurement) }
    let(:list) { MeasurementList.new(ministry_id: ministry.gr_id, mcc: 'DS') }

    it 'returns Measurements' do
      expect(load.first).to be_a Measurement
    end

    it 'loads the GR measurement values' do
      meas = load.first
      expect(meas.total).to eq 4
    end

    it 'filters by mcc_filter' do
      meas.update(mcc_filter: 'DS')
      FactoryGirl.create(:measurement, mcc_filter: 'SLM')

      expect(load.count).to be 1

      meas.update(mcc_filter: nil)

      expect(load.count).to be 1
    end

    it 'filters by ministry hide_values and show_values' do
      meas.update(perm_link: 'lmi_total_custom_to_be_shown')
      meas2 = FactoryGirl.create(:measurement, perm_link: 'lmi_total_hidden')
      FactoryGirl.create(:measurement, perm_link: 'lmi_total_custom_not_shown')

      ministry.update(lmi_hide: ['hidden'], lmi_show: ['to_be_shown'])

      expect(load.count).to be 1

      meas.update(perm_link: 'lmi_total_not_hidden')
      meas2.update(perm_link: 'lmi_total_custom_asdf')

      expect(load.count).to be 1
    end

    it 'loads historical data'
  end
end
