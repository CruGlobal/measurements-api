require 'rails_helper'

describe V5::UserPreferencesSerializer do
  describe 'custom fields' do
    let(:resource) do
      p = FactoryGirl.create(:person)
      ministry = FactoryGirl.create(:ministry)
      p.user_preferences.create(name: 'fake-pref', value: 'mock')
      p.user_map_views.create(ministry_id: ministry.id, lat: -10, long: 9001, zoom: '7000')
      p
    end
    let(:serializer) { V5::UserPreferencesSerializer.new(resource) }
    let(:serialization) { ActiveModel::Serializer::Adapter.create(serializer) }
    let(:hash) { serialization.as_json }

    it 'has attributes' do
      expect(hash['fake-pref']).to eq 'mock'
      expect(hash[:default_map_views]).to be_an Array
      expect(hash[:default_map_views][0]['location']['longitude']).to eq 9001
      expect(hash[:default_map_views][0]['location_zoom']).to eq 7000
    end
  end
end
