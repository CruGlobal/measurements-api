# frozen_string_literal: true

require "rails_helper"

RSpec.describe TrainingCompletion, type: :model do
  let(:ministry) { FactoryGirl.build_stubbed(:ministry) }
  let(:training) { FactoryGirl.build(:training, ministry: ministry) }
  let(:completion) { FactoryGirl.build(:training_completion, training: training, number_completed: 1) }

  describe "validates positive number_completed" do
    it "accepts 1" do
      expect(completion).to be_valid
    end

    it "gives message when value negitive" do
      completion.number_completed = -1
      expect(completion).to_not be_valid
      expect(completion.errors.messages[:number_completed].first).to eq "cannot be negative"
    end
  end
end
