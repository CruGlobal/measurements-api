# frozen_string_literal: true
class UserPreference < ApplicationRecord
  belongs_to :person
end
