# frozen_string_literal: true

require "rails_helper"

describe V5::TrainingSerializer do
  describe "single training" do
    let(:person) { FactoryGirl.build(:person) }
    let(:ministry) { FactoryGirl.build(:ministry) }
    let(:resource) do
      t = FactoryGirl.build_stubbed(:training, ministry: ministry, updated_at: Time.zone.now, created_by: person)
      t.completions.build(phase: 1, number_completed: 20, date: t.date)
      t.completions.build(phase: 2, number_completed: 30, date: t.date + 1.month)
      t
    end
    let(:serializer) { V5::TrainingSerializer.new(resource) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
    let(:hash) { serialization.as_json }

    it "has attributes" do
      expect(hash[:id]).to_not be_nil
      expect(hash[:ministry_id]).to eq ministry.gr_id
      expect(hash[:name]).to eq resource.name
      expect(hash[:date]).to eq "2016-02-19"
      expect(hash[:type]).to_not be_nil
      expect(hash[:mcc]).to_not be_nil
      expect(hash[:latitude]).to_not be_nil
      expect(hash[:longitude]).to_not be_nil
      expect(hash[:created_by]).to_not be_nil
      expect(hash[:gcm_training_completions]).to be_an Array
      expect(hash[:gcm_training_completions].length).to be 2
      # this will tell us if it is using the TrainingCompletionsSerializer
      expect(hash[:gcm_training_completions].first[:date].length).to be 10
    end
  end
end
