require 'rails_helper'

RSpec.describe Measurement::MeasurementRollup, type: :model do
  describe '#run' do
    def measurement_json(value, related_id, dimension = nil)
      {
        id: SecureRandom.uuid, period: '03-2016',
        value: value, related_entity_id: related_id, dimension: dimension
      }
    end

    def measurements_json(related_entity_id = nil)
      {
        measurement_types: [{
          perm_link: 'LMI',
          measurements: [
            measurement_json(3, related_entity_id, 'DS'),
            measurement_json(3, related_entity_id, 'DS_asdf'),
            measurement_json(1, related_entity_id)
          ]
        }]
      }
    end

    let(:measurement) { FactoryGirl.create(:measurement) }
    let(:ministry) { FactoryGirl.create(:ministry) }
    it 'calls the GR' do
      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types")
             .with(query: hash_including)
             .to_return(body: measurements_json(ministry.gr_id).to_json)
      gr_update_stub = WebMock.stub_request(:post, "#{ENV['GLOBAL_REGISTRY_URL']}measurements")

      Measurement::MeasurementRollup.new.run(measurement.perm_link, ministry.gr_id, '03-2016', 'SLM')

      expect(gr_update_stub).to have_been_requested.times(1)
    end

    it 'rolls up parent ministry' do
      child_ministry = FactoryGirl.create(:ministry, parent: ministry)

      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types")
             .with(query: hash_including)
             .to_return(body: measurements_json(ministry.gr_id).to_json)
      gr_update_stub = WebMock.stub_request(:post, "#{ENV['GLOBAL_REGISTRY_URL']}measurements")

      Measurement::MeasurementRollup.new.run(measurement.perm_link, child_ministry.gr_id, '03-2016', 'SLM')
      expect(gr_update_stub).to have_been_requested.times(2)
    end

    it 'rolls up parent measurements' do
      child_measurement = FactoryGirl.create(:measurement, parent: measurement, perm_link: 'lmi_total_unique')

      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types")
             .with(query: hash_including)
             .to_return(body: measurements_json(ministry.gr_id).to_json)
      child_measurement_type_json = measurements_json(ministry.gr_id)[:measurement_types].first
      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{child_measurement.total_id}")
             .with(query: hash_including)
             .to_return(body: { measurement_type: child_measurement_type_json }.to_json)
      WebMock.stub_request(:get, "#{ENV['GLOBAL_REGISTRY_URL']}measurement_types/#{measurement.total_id}")
             .with(query: hash_including)
             .to_return(body: { measurement_type: child_measurement_type_json }.to_json)
      gr_update_stub = WebMock.stub_request(:post, "#{ENV['GLOBAL_REGISTRY_URL']}measurements")

      Measurement::MeasurementRollup.new.run(child_measurement.perm_link, ministry.gr_id, '03-2016', 'SLM')
      expect(gr_update_stub).to have_been_requested.times(2)
    end
  end
end
