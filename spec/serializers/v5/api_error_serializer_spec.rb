require 'rails_helper'

RSpec.describe V5::ApiErrorSerializer do
  context 'ApiError Serialization' do
    let(:api_error) { ApiError.new(message: 'Sample Message') }

    let(:serializer) { V5::ApiErrorSerializer.new(api_error) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }

    subject do
      JSON.parse(serialization.to_json)
    end

    it 'has a reason that matches #message' do
      expect(subject['reason']).to eql(api_error.message)
    end

    it 'has a reason of \'INVALID_SESSION\' when message is \'Bad token\'' do
      api_error.message = 'Bad token'
      expect(subject['reason']).to eql('INVALID_SESSION')
    end
  end
end
