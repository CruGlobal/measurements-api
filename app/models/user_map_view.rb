# frozen_string_literal: true
class UserMapView < ApplicationRecord
  belongs_to :person
  belongs_to :ministry
end
