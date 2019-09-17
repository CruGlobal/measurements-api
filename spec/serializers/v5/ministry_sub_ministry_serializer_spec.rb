# frozen_string_literal: true

require "rails_helper"

RSpec.describe V5::MinistrySubMinistrySerializer do
  describe "a sub ministry" do
    let(:ministry) { FactoryGirl.create(:ministry) }
    let(:serializer) { V5::MinistrySubMinistrySerializer.new(ministry) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
    let(:json) { serialization.as_json }

    it "has exactly min_id, name and min_code" do
      expect(json.keys).to contain_exactly(:min_id, :name, :min_code)
      expect(json[:min_id]).to_not be_nil
      expect(json[:name]).to_not be_nil
      expect(json[:min_code]).to_not be_nil
    end
  end
end
