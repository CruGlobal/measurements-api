# frozen_string_literal: true
require 'rails_helper'

RSpec.describe ApiError do
  context 'ApiError object' do
    let(:message) { 'Sample Message' }
    let(:api_error) { ApiError.new(message: message) }

    it 'has a message that matches the parameter' do
      expect(api_error.message).to eql(message)
    end
  end
end
