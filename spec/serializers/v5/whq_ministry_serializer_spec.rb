# frozen_string_literal: true

require "rails_helper"

RSpec.describe V5::WhqMinistrySerializer do
  describe "a ministry" do
    let(:area) { FactoryBot.create(:area, name: "Testing Area", code: "TEST") }
    let(:ministry) { FactoryBot.create(:ministry, ministry_scope: "National", area: area) }
    let(:serializer) { V5::WhqMinistrySerializer.new(ministry) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
    let(:json) { serialization.as_json }

    it "has properties" do
      expect(json.keys).to contain_exactly(:ministry_id, :name, :min_code, :area_name, :area_code)
      expect(json[:ministry_id]).to be_uuid.and(eq ministry.gr_id)
      expect(json[:name]).to be_a(String).and(eq ministry.name)
      expect(json[:min_code]).to be_a(String).and(eq ministry.min_code)
      expect(json[:area_name]).to be_a(String).and(eq area.name)
      expect(json[:area_code]).to be_a(String).and(eq area.code)
    end
  end
end
