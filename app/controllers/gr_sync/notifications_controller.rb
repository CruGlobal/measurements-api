# frozen_string_literal: true
module GrSync
  class NotificationsController < ApplicationController
    def create
      if params[:confirmation_url].present?
        ConfirmSubscriptionWorker.perform_async(params[:confirmation_url])
      else
        NotificationWorker.perform_async(notification_params)
      end
      render nothing: true
    end

    private

    def notification_params
      # Don't use params because it will set action to 'create' because that's
      # the controller action when what we really want is the action of the
      # notification that global registry sent to us.
      request.POST.slice(:action, :id, :client_integration_id, :triggered_by,
                         :entity_type)
    end
  end
end
