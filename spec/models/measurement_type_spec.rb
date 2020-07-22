# frozen_string_literal: true

require "rails_helper"

RSpec.describe MeasurementType, type: :model do
  let(:ministry) { FactoryBot.create(:ministry) }

  describe "#destroy" do
    before do
      @measurement = FactoryBot.create(:measurement)
      @measurement_type = MeasurementType.new(measurement: @measurement)

      @gr_meas_delete_total_stub =
        WebMock.stub_request(:delete, "#{ENV["GLOBAL_REGISTRY_URL"]}/measurement_types/#{@measurement.total_id}")
          .to_return(status: 200, headers: {}, body: "{}")
      @gr_meas_delete_local_stub =
        WebMock.stub_request(:delete, "#{ENV["GLOBAL_REGISTRY_URL"]}/measurement_types/#{@measurement.local_id}")
          .to_return(status: 200, headers: {}, body: "{}")
      @gr_meas_delete_person_stub =
        WebMock.stub_request(:delete, "#{ENV["GLOBAL_REGISTRY_URL"]}/measurement_types/#{@measurement.person_id}")
          .to_return(status: 200, headers: {}, body: "{}")
    end

    it "removes Measurement from the db" do
      expect { @measurement_type.destroy }.to change(Measurement, :count).by(-1)
    end

    it "deletes it from GR" do
      @measurement_type.destroy
      expect(@gr_meas_delete_total_stub).to have_been_requested
      expect(@gr_meas_delete_local_stub).to have_been_requested
      expect(@gr_meas_delete_person_stub).to have_been_requested
    end

    it "only deletes if it doesn't have children" do
      FactoryBot.create(:measurement, parent: @measurement)

      expect { @measurement_type.destroy }.to raise_error("measurements with children can not be destroyed")
        .and(change(Measurement, :count).by(0))
    end

    it "also deletes attached translations" do
      FactoryBot.create(:measurement_translation, measurement: @measurement)
      expect { @measurement_type.destroy }.to change(MeasurementTranslation, :count).by(-1)
    end
  end

  describe "#all_localized_with" do
    it "loads parent translations" do
      parent_ministry = FactoryBot.create(:ministry)
      ministry.update(parent: parent_ministry)
      measurement1 = FactoryBot.create(:measurement)
      FactoryBot.create(:measurement_translation, measurement: measurement1, language: "fr",
                                                   ministry: ministry, name: "Unique name")
      measurement2 = FactoryBot.create(:measurement)
      FactoryBot.create(:measurement_translation, measurement: measurement2, language: "fr",
                                                   ministry: parent_ministry, name: "Another unique name")
      measurement3 = FactoryBot.create(:measurement)

      types = MeasurementType.all_localized_with(locale: "fr", ministry_id: ministry.id)

      expect(types.count).to be 3
      expect(types.first.localized_name).to eq "Unique name"
      expect(types.second.localized_name).to eq "Another unique name"
      expect(types.last.localized_name).to eq measurement3.english
    end
  end
end
