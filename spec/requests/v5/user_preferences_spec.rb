# frozen_string_literal: true
require 'rails_helper'

RSpec.describe 'V5::UserPreferences', type: :request do
  let(:person) { FactoryGirl.create(:person) }
  let(:ministry) { FactoryGirl.create(:ministry) }
  let!(:preferences) do
    person.user_content_locales.create(ministry: ministry, locale: 'en-US')
    person.user_map_views.create(ministry: ministry, lat: 12.3456789, long: -12.3456789, zoom: 3)
    person.user_measurement_states.create(mcc: 'gcm', perm_link_stub: 'build_holyspirit', visible: false)
    person.user_measurement_states.create(mcc: 'gcm', perm_link_stub: 'win_exposing', visible: true)
    person.user_measurement_states.create(mcc: 'slm', perm_link_stub: 'build_disciples', visible: false)
    person.user_preferences.create(name: 'preferred_ministry', value: ministry.gr_id)
    person.user_preferences.create(name: 'preferred_mcc', value: 'gcm')
    person.user_preferences.create(name: 'supported_staff', value: '0')
    person.user_preferences.create(name: 'hide_reports_tab', value: '1')
  end
  let(:json) { JSON.parse(response.body) }

  describe 'GET /v5/user_preferences' do
    it 'responds successfully preferences' do
      get '/v5/user_preferences', headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}" }

      expect(response).to be_successful
      expect(response).to have_http_status :ok
      expect(json).to include_json(content_locales: { ministry.gr_id => 'en-US' },
                                   preferred_ministry: ministry.gr_id,
                                   preferred_mcc: 'gcm',
                                   supported_staff: '0',
                                   hide_reports_tab: '1',
                                   default_map_views: [{ ministry_id: ministry.gr_id,
                                                         location: { latitude: 12.3456789, longitude: -12.3456789 },
                                                         location_zoom: 3 }],
                                   default_measurement_states: { slm: { build_disciples: 0 },
                                                                 llm: {},
                                                                 ds: {},
                                                                 gcm: { build_holyspirit: 0, win_exposing: 1 } })
    end
  end

  describe 'POST /v5/user_preferences' do
    let!(:other) { FactoryGirl.create(:ministry) }
    it 'responds successfully with updated preferences' do
      post '/v5/user_preferences',
           params: { custom_property: 'value',
                     preferred_mcc: 'slm',
                     preferred_ministry: nil,
                     default_map_views: [{ ministry_id: other.gr_id,
                                           location: { latitude: 98.7654321, longitude: -98.7654321 },
                                           location_zoom: 12 }],
                     content_locales: { other.gr_id => 'fr-FR' },
                     default_measurement_states: { slm: { build_disciples: 1 },
                                                   gcm: { build_holyspirit: 0 },
                                                   ds: { send_mult_disc: 1 } } },
           headers: { 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}" }

      expect(response).to be_successful
      expect(response).to have_http_status :ok
      expect(json).to include_json(content_locales: { other.gr_id => 'fr-FR' },
                                   preferred_mcc: 'slm',
                                   supported_staff: '0',
                                   hide_reports_tab: '1',
                                   default_map_views: [{ ministry_id: ministry.gr_id,
                                                         location: { latitude: 12.3456789, longitude: -12.3456789 },
                                                         location_zoom: 3 },
                                                       { ministry_id: other.gr_id,
                                                         location: { latitude: 98.7654321, longitude: -98.7654321 },
                                                         location_zoom: 12 }],
                                   default_measurement_states: { slm: { build_disciples: 0 },
                                                                 llm: {},
                                                                 ds: { send_mult_disc: 0 },
                                                                 gcm: { build_holyspirit: 0, win_exposing: 1 } })
    end
  end
end
