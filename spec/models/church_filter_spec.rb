require 'rails_helper'

RSpec.describe ChurchFilter, type: :model do
  let(:user) { FactoryGirl.create(:person) }
  let(:ministry) { FactoryGirl.create(:ministry) }
  let!(:assignment) { FactoryGirl.create(:assignment, person: user, ministry: ministry, role: 7) }
  let!(:parent_church) do
    FactoryGirl.create(:church, target_area: ministry,
                                development: 2, latitude: -10, longitude: 10)
  end
  let!(:child_church) do
    FactoryGirl.create(:church, development: 3, latitude: 10, longitude: 10,
                                parent: parent_church, target_area: ministry)
  end

  context 'filter by development' do
    it 'shows all' do
      filters = { hide_church: 'false', show_all: '1', ministry_id: ministry.id }
      filtered = ChurchFilter.new(filters).filter(Church.all)

      expect(filtered).to include parent_church
      expect(filtered).to include child_church
    end

    it 'filters correctly' do
      filters = { hide_group: '1', hide_church: '1', show_all: '1', ministry_id: ministry.id }
      filtered = ChurchFilter.new(filters).filter(Church.all)

      expect(filtered).to_not include parent_church
      expect(filtered).to_not include child_church
    end
  end

  context 'filter by show all' do
    let(:unrelated_pub_church) { FactoryGirl.create(:church_with_ministry) }
    let(:unrelated_private_church) do
      FactoryGirl.create(:church_with_ministry, security: Church.securities['private_church'])
    end

    it 'includes public churches' do
      filters = { show_all: '1', ministry_id: ministry.id }
      filtered = ChurchFilter.new(filters).filter(Church.all)

      expect(filtered).to include unrelated_pub_church
      expect(filtered).to_not include unrelated_private_church
    end
    it "doesn't include public churches" do
      filters = { show_all: '0', ministry_id: ministry.id }
      filtered = ChurchFilter.new(filters).filter(Church.all)

      expect(filtered).to_not include unrelated_pub_church
      expect(filtered).to_not include unrelated_private_church
    end
  end

  context 'filter by show tree' do
    let!(:child_ministry) { FactoryGirl.create(:ministry, parent: ministry) }
    let!(:church2) do
      FactoryGirl.create(:church, target_area: child_ministry,
                                  security: Church.securities['private_church'])
    end
    let!(:local_private_church) do
      FactoryGirl.create(:church, target_area: child_ministry,
                                  security: Church.securities['local_private_church'])
    end
    let(:filters) { { ministry_id: ministry.id, show_tree: '1' } }
    let(:filtered) { ChurchFilter.new(filters).filter(Church.all) }
    let(:admin_power) { Power.new(user, ministry) }

    context 'as admin user' do
      it 'includes child churches' do
        Power.with_power(admin_power) do
          expect(filtered).to include church2
        end
      end

      it "doesn't include local_private churches" do
        Power.with_power(admin_power) do
          expect(filtered).to_not include local_private_church
        end
      end

      it "doesn't include child churches" do
        filters[:show_tree] = '0'

        Power.with_power(admin_power) do
          expect(filtered).to_not include church2
        end
      end
    end

    context 'as unknown user' do
      it "doesn't include private child churches" do
        user.assignments.first.update(role: 0)

        Power.with_power(admin_power) do
          expect(filtered).to_not include church2
        end
      end
    end
  end

  context 'filter by lat/long' do
    let!(:church2) do
      FactoryGirl.create(:church, target_area: ministry, latitude: 10, longitude: 40)
    end

    let(:filters) do
      { ministry_id: ministry.id, show_all: '1',
        lat_min: 0, lat_max: 10, long_min: 0, long_max: 30 }
    end
    let(:filtered) { ChurchFilter.new(filters).filter(Church.all) }

    it 'filters out churches' do
      expect(filtered).to include child_church
      expect(filtered).to_not include parent_church
      expect(filtered).to_not include church2
    end

    it 'filters over the date-line' do
      filters[:long_min] = 50
      filters[:lat_min] = -10
      parent_church.update(latitude: -10, longitude: 60)
      child_church.update(latitude: 10, longitude: 60)

      expect(filtered).to include child_church
      expect(filtered).to include parent_church
      expect(filtered).to_not include church2
    end
  end

  context 'filter by period' do
    before do
      # hasn't started yet
      parent_church.update(start_date: 1.year.from_now)
      # already ended
      child_church.update(end_date: 1.month.ago)
    end
    let!(:church2) do
      FactoryGirl.create(:church, start_date: 1.year.ago, end_date: 1.year.from_now,
                                  target_area: ministry)
    end
    let(:filters) { { show_all: '1', period: Time.zone.today.strftime('%Y-%m') } }
    let(:filtered) { ChurchFilter.new(filters).filter(Church.all) }

    it 'filters out churches' do
      expect(filtered).to_not include child_church
      expect(filtered).to_not include parent_church
      expect(filtered).to include church2
    end
  end
end
