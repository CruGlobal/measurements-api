# frozen_string_literal: true
class MonitorsController < ApplicationController
  newrelic_ignore

  def lb
    render plain: 'OK'
  end
end
