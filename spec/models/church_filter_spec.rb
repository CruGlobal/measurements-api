require 'rails_helper'

RSpec.describe ChurchFilter, type: :model do
  let(:user) { Person.new(first_name: 'Test', last_name: 'User') }
  let(:ministry) { Ministry.create(name: 'asdf', ministry_id: SecureRandom.uuid, min_code: 'test') }
  let!(:parent_church) { FactoryGirl.create(:church, target_area_id: ministry.ministry_id, development: 2) }
  let!(:child_church) do
    FactoryGirl.create(:church, target_area_id: 'asdf', development: 3,
                                parent_id: parent_church.church_id)
  end

  context 'filter by development' do
    it 'shows all' do
      filters = { hide_church: 'false', show_all: '1', ministry_id: ministry.ministry_id }
      filtered = ChurchFilter.new(filters, user).filter(Church.all)

      expect(filtered).to include parent_church
      expect(filtered).to include child_church
    end

    it 'filters correctly' do
      filters = { hide_group: '1', hide_church: '1', show_all: '1', ministry_id: ministry.ministry_id }
      filtered = ChurchFilter.new(filters, user).filter(Church.all)

      expect(filtered).to_not include parent_church
      expect(filtered).to_not include child_church
    end
  end

  context 'filter by show all' do
    let(:unrelated_pub_church) { FactoryGirl.create(:church, target_area_id: SecureRandom.uuid) }
    let(:unrelated_private_church) do
      FactoryGirl.create(:church, target_area_id: SecureRandom.uuid,
                                  security: Church.securities['private_church'])
    end

    it 'includes public churches' do
      filters = { show_all: '1', ministry_id: ministry.ministry_id }
      filtered = ChurchFilter.new(filters, user).filter(Church.all)

      expect(filtered).to include unrelated_pub_church
      expect(filtered).to_not include unrelated_private_church
    end
    it "doesn't include public churches" do
      filters = { show_all: '0', ministry_id: ministry.ministry_id }
      filtered = ChurchFilter.new(filters, user).filter(Church.all)

      expect(filtered).to_not include unrelated_pub_church
      expect(filtered).to_not include unrelated_private_church
    end
  end
end
