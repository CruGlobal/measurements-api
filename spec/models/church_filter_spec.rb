require 'rails_helper'

RSpec.describe ChurchFilter, type: :model do
  let(:user) { Person.create(first_name: 'Test', last_name: 'User') }
  let(:ministry) { Ministry.create(ministry_id: 'asdf') }
  let!(:parent_church) { FactoryGirl.create(:church, target_area_id: 'asdf', development: 2) }
  let!(:child_church) do
    FactoryGirl.create(:church, target_area_id: 'asdf', development: 3,
                                parent_id: parent_church.church_id)
  end

  context 'filter by development' do
    it 'filters correctly' do
      filtered = ChurchFilter.new({ hide_church: 'false', show_all: '0' }, user).filter(Church.all)

      expect(filtered).to include parent_church
      expect(filtered).to include child_church
    end

    it 'filters correctly' do
      filtered = ChurchFilter.new({ hide_group: '1', hide_church: '1', show_all: '0' }, user).filter(Church.all)

      expect(filtered).to_not include parent_church
      expect(filtered).to_not include child_church
    end
  end
end
