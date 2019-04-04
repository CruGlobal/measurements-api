# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'V5::Images', type: :request do
  describe 'GET /v5/languages' do
    it 'responds with languages' do
      get '/v5/languages'

      expect(response).to be_successful
      expect(response).to have_http_status :ok
      json = JSON.parse(response.body)
      expect(json.length).to be 222
      expect(json.sample.keys).to contain_exactly('iso_code', 'native_name', 'english_name', 'is_rtl')
    end
  end
end
