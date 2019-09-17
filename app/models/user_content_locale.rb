# frozen_string_literal: true

class UserContentLocale < ApplicationRecord
  belongs_to :person
  belongs_to :ministry
end
