# frozen_string_literal: true

require "rails_helper"

describe V5::AuditSerializer do
  describe "single audit" do
    let(:ministry) { FactoryBot.build(:ministry) }
    let(:person) { FactoryBot.build(:person) }
    let(:resource) do
      FactoryBot.build_stubbed(:audit, ministry: ministry, person: person,
                                        created_at: Time.zone.parse("00:00 06/08/2015"))
    end
    let(:serializer) { V5::AuditSerializer.new(resource) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
    let(:hash) { serialization.as_json }

    it "has attributes" do
      expect(hash[:timestamp]).to eq "2015-08-06"
      expect(hash[:message]).to_not be_nil
      expect(hash[:type]).to eq "NEW_STORY"
      expect(person.gr_id).to be_uuid
      expect(hash[:person_id]).to eq person.gr_id
      expect(hash[:ministry_id]).to_not be_nil
      expect(hash[:ministry_id]).to eq ministry.gr_id
      expect(hash[:ministry_name]).to_not be_nil
    end
  end
end
