require 'rails_helper'

RSpec.describe ChurchFilter, type: :model do
  let(:user) { Person.create(first_name: 'Test', last_name: 'User') }
  let(:ministry) { Ministry.create(ministry_id: 'asdf') }
  let!(:parent_church) { FactoryGirl.create(:church, target_area_id: 'asdf', development: 1) }
  let!(:child_church) { FactoryGirl.create(:church, target_area_id: 'asdf', parent_id: parent_church.church_id) }

  context 'filter by development' do
    let(:filtered) { ChurchFilter.new({development: 1, show_all: '0'}, user).filter(Church.all) }
    it 'filters correctly' do
      expect(filtered).to include parent_church
    end
  end
end
