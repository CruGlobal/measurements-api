# frozen_string_literal: true
module GrSync
  class NotificationsController < ApplicationController
    def create
      if params[:confirmation_url].present?
        ConfirmSubscriptionWorker.perform_async(params[:confirmation_url])
      else
        NotificationWorker.perform_async(params)
      end
      render nothing: true
    end
  end
end
