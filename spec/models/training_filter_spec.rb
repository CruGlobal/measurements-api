# frozen_string_literal: true
require 'rails_helper'

RSpec.describe TrainingFilter, type: :model do
  let(:user) { FactoryGirl.create(:person) }
  let(:ministry) { FactoryGirl.create(:ministry) }
  let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }
  let!(:training1) do
    FactoryGirl.create(:training, ministry: ministry, date: 1.week.ago)
  end

  context 'filter by show tree' do
    let!(:child_ministry) { FactoryGirl.create(:ministry, parent: ministry) }
    let!(:child_training) do
      FactoryGirl.create(:training, ministry: child_ministry, date: 1.week.ago)
    end
    let(:filters) { { ministry_id: ministry.gr_id, show_tree: '1' } }
    let(:filtered) { TrainingFilter.new(filters).filter(Training.all) }

    it 'includes child trainings' do
      expect(filtered).to include training1
      expect(filtered).to include child_training
    end

    it "doesn't include trainings on child ministries" do
      filters[:show_tree] = '0'

      expect(filtered).to include training1
      expect(filtered).to_not include child_training
    end
  end

  context 'filter by time' do
    before do
      # setup some trainings
    end
    let!(:old_training) do
      FactoryGirl.create(:training, ministry: ministry, date: 2.years.ago)
    end
    let(:filters) { { ministry_id: ministry.gr_id, show_all: '1' } }
    let(:filtered) { TrainingFilter.new(filters).filter(Training.all) }

    it 'includes old trainings' do
      expect(filtered).to include training1
      expect(filtered).to include old_training
    end

    it "doesn't include old trainings" do
      filters[:show_all] = '0'

      expect(filtered).to include training1
      expect(filtered).to_not include old_training
    end
  end
end
