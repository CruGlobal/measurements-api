# frozen_string_literal: true

class MonitorsController < ApplicationController
  def lb
    render plain: "OK"
  end
end
