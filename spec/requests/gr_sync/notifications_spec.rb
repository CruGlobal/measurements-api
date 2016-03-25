# frozen_string_literal: true
require 'rails_helper'

describe 'Global registry notifications', type: :request do
  context '#create' do
    it 'queues a subscription confirmation worker if confirmation url present' do
      allow(GrSync::ConfirmSubscriptionWorker).to receive(:perform_async)

      post gr_sync_notifications_url, confirmation_url: 'global-registry.org/confirm/abc'

      expect(GrSync::ConfirmSubscriptionWorker).to have_received(:perform_async)
        .with('global-registry.org/confirm/abc')
    end

    it 'queues a notification worker if confirmation url not present' do
      allow(GrSync::NotificationWorker).to receive(:perform_async)

      post gr_sync_notifications_url, action: 'updated', id: '1f'

      expect(GrSync::NotificationWorker).to have_received(:perform_async)
        .with('action' => 'updated', 'id' => '1f')
    end
  end
end
