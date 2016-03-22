# frozen_string_literal: true
require 'rails_helper'

describe V5::TrainingSerializer do
  describe 'single training' do
    let(:ministry) { FactoryGirl.build(:ministry) }
    let(:resource) do
      t = FactoryGirl.build_stubbed(:training, ministry: ministry)
      FactoryGirl.build_stubbed(:training_completion, training: t, phase: 1, number_completed: 20, date: t.date)
    end
    let(:serializer) { V5::TrainingCompletionSerializer.new(resource) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
    let(:hash) { serialization.as_json }

    it 'has attributes' do
      expect(hash[:id]).to_not be_nil
      expect(hash[:phase]).to_not be_nil
      expect(hash[:number_completed]).to_not be_nil
      expect(hash[:date]).to eq '2016-02-19'
      expect(hash[:training_id]).to eq resource.training.id
    end
  end
end
