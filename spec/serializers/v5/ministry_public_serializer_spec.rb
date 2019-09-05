# frozen_string_literal: true

require "rails_helper"

RSpec.describe V5::MinistryPublicSerializer do
  describe "a ministry" do
    let(:ministry) { FactoryGirl.create(:ministry) }
    let(:serializer) { V5::MinistryPublicSerializer.new(ministry) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
    let(:json) { serialization.as_json }

    it "has exactly ministry_id and name" do
      expect(json.keys).to contain_exactly(:ministry_id, :name)
      expect(json[:ministry_id]).to_not be_nil
      expect(json[:name]).to_not be_nil
    end
  end
end
