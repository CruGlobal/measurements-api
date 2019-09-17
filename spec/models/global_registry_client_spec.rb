# frozen_string_literal: true

require "spec_helper"

describe GlobalRegistryClient do
  it "stores global registry config and gives entity type clients with that config" do
    client = GlobalRegistryClient.new(access_token: "test-token-xyz")
    entity_client = double
    allow(GlobalRegistry::Entity).to receive(:new) { entity_client }

    expect(client.entity).to eq(entity_client)

    expect(GlobalRegistry::Entity).to have_received(:new)
      .with(access_token: "test-token-xyz")
  end
end
