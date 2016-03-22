# frozen_string_literal: true
class UserMapView < ActiveRecord::Base
  belongs_to :person
  belongs_to :ministry
end
