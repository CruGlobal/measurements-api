require 'rails_helper'

describe V5::TokenAndUserSerializer do
  describe 'token request' do
    let(:resource) do
      token = CruLib::AccessToken.new(
        key_guid: 'asdf-1234',
        email: 'email@email.com',
        first_name: 'Tony',
        last_name: 'Stark'
      )
      TokenAndUser.new(token, Person.create(
                                person_id: 'asdf',
                                first_name: token.first_name,
                                last_name: token.last_name,
                                cas_guid: token.key_guid,
                                cas_username: token.email
      ))
    end
    let(:serializer) { V5::TokenAndUserSerializer.new(resource) }
    let(:serialization) { ActiveModel::Serializer::Adapter.create(serializer) }
    let(:hash) { serialization.as_json }

    it 'has attributes' do
      expect(hash[:status]).to eq 'success'
      expect(hash[:session_ticket]).to_not be_nil
      expect(hash[:assignments]).to_not be_nil
      expect(hash[:user_preferences]).to_not be_nil
      expect(hash[:user_preferences][:content_locales]).to_not be_nil
      expect(hash[:user]).to_not be_nil
      expect(hash[:user][:first_name]).to eq 'Tony'
      expect(hash[:user][:last_name]).to eq 'Stark'
      expect(hash[:user][:cas_username]).to eq resource.access_token.email
      expect(hash[:user][:person_id]).to eq resource.person.person_id
    end

    it 'has assignments' do
      assignments = hash[:assignments]
      expect(assignments).to be_an Array
    end
  end
end
