# frozen_string_literal: true
class UserPreference < ActiveRecord::Base
  belongs_to :person
end
