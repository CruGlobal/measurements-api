# frozen_string_literal: true
require 'rails_helper'

describe GrSync::MeasurementPush, '#push_to_gr' do
  context '#push_to_gr' do
    it 'posts measurement to Global Registry' do
      let(:measurement) do
        { measurement_type_id: measurement.local_id, source: 'gma-app',
          value: 123, ministry_id: ministry.gr_id, mcc: 'gcm' }
      end
      gr_client = GlobalRegistryClient.new
      post_gr_stub = WebMock.stub_request(:post, "#{ENV['GLOBAL_REGISTRY_URL']}/measurements")

      GrSync::MeasurementPush.new(gr_client).push_to_gr(measurement)
      expect(post_gr_stub).to have_been_requested
    end
  end
end
