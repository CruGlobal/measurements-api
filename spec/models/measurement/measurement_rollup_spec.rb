# frozen_string_literal: true

require "rails_helper"

RSpec.describe Measurement::MeasurementRollup, type: :model do
  describe "#run" do
    def measurement_json(value, related_id, dimension = nil)
      {
        id: SecureRandom.uuid, period: "03-2016",
        value: value, related_entity_id: related_id, dimension: dimension,
      }
    end

    def measurements_json(related_entity_id = nil)
      {
        measurement_type: {
          perm_link: "LMI",
          measurements: [
            measurement_json(3, related_entity_id, "DS"),
            measurement_json(3, related_entity_id, "DS_asdf"),
            measurement_json(1, related_entity_id),
          ],
        },
      }
    end

    let(:measurement) { FactoryGirl.create(:measurement) }
    let(:ministry) { FactoryGirl.create(:ministry) }
    it "calls the GR" do
      [:total, :local, :person].each do |mt|
        WebMock.stub_request(:get, %r{#{ENV['GLOBAL_REGISTRY_URL']}/measurement_types/#{measurement.send("#{mt}_id")}})
          .to_return(body: measurements_json(ministry.gr_id).to_json)
      end
      gr_update_stub = WebMock.stub_request(:post, "#{ENV["GLOBAL_REGISTRY_URL"]}/measurements")
        .to_return(status: 200, headers: {}, body: "{}")

      Measurement::MeasurementRollup.new.run(measurement, ministry.gr_id, "03-2016", "SLM")

      expect(gr_update_stub).to have_been_requested.times(1)
    end

    it "rolls up parent measurements" do
      child_measurement = FactoryGirl.create(:measurement, parent: measurement, perm_link: "lmi_total_unique")

      [:total, :local, :person].each do |mt|
        WebMock.stub_request(:get, %r{#{ENV['GLOBAL_REGISTRY_URL']}/measurement_types/#{measurement.send("#{mt}_id")}})
          .to_return(body: measurements_json(ministry.gr_id).to_json)
      end
      [:total, :local, :person].each do |mt|
        url_regex = %r{#{ENV['GLOBAL_REGISTRY_URL']}/measurement_types/#{child_measurement.send("#{mt}_id")}}
        WebMock.stub_request(:get, url_regex)
          .to_return(body: measurements_json(ministry.gr_id).to_json)
      end
      gr_update_stub = WebMock.stub_request(:post, "#{ENV["GLOBAL_REGISTRY_URL"]}/measurements")
        .to_return(status: 200, headers: {}, body: "{}")

      Measurement::MeasurementRollup.new.run(child_measurement, ministry.gr_id, "03-2016", "SLM")

      expect(gr_update_stub).to have_been_requested.times(2)
    end
  end
end
