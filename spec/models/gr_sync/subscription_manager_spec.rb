require 'rails_helper'

describe GrSync::SubscriptionManager, '#ensure_subscribed_to_all' do
  it 'creates a subscription for any entity type ids not already subscribed' do
    endpoint = 'http://test.host/gr/notification'
    existing_subs = [{ 'endpoint' => endpoint, 'entity_type_id' => '1f' }]
    subscription_client = double(get_all_pages: existing_subs, post: nil)
    allow(GlobalRegistry::Subscription).to receive(:new) { subscription_client }

    GrSync::SubscriptionManager.new(%w(1f 2f), endpoint).ensure_subscribed_to_all

    expect(subscription_client).to have_received(:post)
      .with(subscription: { entity_type_id: '2f', endpoint: endpoint })
  end
end
