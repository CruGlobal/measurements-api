require 'rails_helper'

RSpec.describe Training, type: :model do
  let(:ministry) { FactoryGirl.build_stubbed(:ministry) }
  let(:training) { FactoryGirl.build(:training, ministry: ministry) }

  describe 'validates type value' do
    it 'accepts value in list' do
      expect(training).to be_valid
    end

    it 'gives message when value not on list' do
      training.type = 'ABC'
      expect(training).to_not be_valid
      expect(training.errors.messages[:type].first).to eq "Training type is not recognized: 'ABC'"
    end
  end
end
