require 'rails_helper'

describe V5::TrainingSerializer do
  describe 'single training' do
    let(:ministry) { FactoryGirl.build(:ministry) }
    let(:resource) { FactoryGirl.create(:training, ministry: ministry) }
    let(:serializer) { V5::TrainingSerializer.new(resource) }
    let(:serialization) { ActiveModel::Serializer::Adapter.create(serializer) }
    let(:hash) { serialization.as_json }

    it 'has attributes' do
      expect(hash[:id]).to_not be_nil
      expect(hash[:ministry_id]).to eq ministry.gr_id
      expect(hash[:name]).to eq resource.name
      expect(hash[:date]).to eq '2016-02-19'
      expect(hash[:type]).to_not be_nil
      expect(hash[:mcc]).to_not be_nil
      expect(hash[:latitude]).to_not be_nil
      expect(hash[:longitude]).to_not be_nil
      expect(hash[:gcm_training_completions]).to be_an Array
    end
  end
end
