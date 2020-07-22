# frozen_string_literal: true

require "rails_helper"

describe V5::ChurchSerializer do
  describe "cluster of churchs" do
    let(:ministry) { FactoryBot.build(:ministry) }
    let(:resource) do
      @p = FactoryBot.create(:church, ministry: ministry)
      c = FactoryBot.create(:church, jf_contrib: true, ministry: ministry, parent: @p)
      [@p, c, FactoryBot.create(:church, parent: c, ministry: ministry)]
    end
    let(:serializer) { V5::ChurchClusterSerializer.new(resource) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
    let(:hash) { serialization.as_json }

    it "has attributes" do
      expect(hash[:latitude]).to_not be_nil
      expect(hash[:longitude]).to_not be_nil
      expect(hash[:jf_contrib]).to be 1
      expect(hash[:cluster_count]).to be 3
      expect(hash[:id]).to_not be_nil
      expect(hash[:gr_id]).to be_nil
      expect(hash[:ministry_id]).to eq ministry.gr_id
      expect(hash[:parents]).to eq []
    end
  end
end
