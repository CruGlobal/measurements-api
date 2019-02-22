# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def initialize(attributes = nil, _options = {})
    super(attributes)
  end
end
