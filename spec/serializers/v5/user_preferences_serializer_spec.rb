require 'rails_helper'

describe V5::UserPreferencesSerializer do
  describe 'custom fields' do
    let(:resource) do
      p = Person.create(
        person_id: 'asdf',
        first_name: 'first',
      )
      p.user_preferences.create(name: 'fake-pref', value: 'mock')
      p
    end
    let(:serializer) { V5::UserPreferencesSerializer.new(resource) }
    let(:serialization) { ActiveModel::Serializer::Adapter.create(serializer) }
    let(:hash) { serialization.as_json }

    it 'has attributes' do
      p hash
      expect(hash['fake-pref']).to eq 'mock'
    end
  end
end
