# frozen_string_literal: true

class ApplicationController < ActionController::API
  force_ssl(if: :ssl_configured?, except: :lb)

  def ssl_configured?
    !Rails.env.development? && !Rails.env.test?
  end
end
