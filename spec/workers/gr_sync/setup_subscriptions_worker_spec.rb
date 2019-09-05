# frozen_string_literal: true

require "rails_helper"

describe GrSync::SetupSubscriptionsWorker, "#perform" do
  it "subscribes the relevant entity types ids with correct endpoint" do
    endpoint = "https://test.host/gr_sync/asdf/notifications"
    allow(GrSync::SubscribedEntities).to receive(:entity_type_ids) { %w[1f 2f] }
    manager = double(ensure_subscribed_to_all: nil)
    allow(GrSync::SubscriptionManager).to receive(:new) { manager }

    GrSync::SetupSubscriptionsWorker.new.perform

    expect(GrSync::SubscriptionManager).to have_received(:new)
      .with(%w[1f 2f], endpoint)
    expect(manager).to have_received(:ensure_subscribed_to_all)
  end
end
