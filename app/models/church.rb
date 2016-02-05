class Church < ActiveRecord::Base
  belongs_to :parent, class_name: 'Church'
  has_many :children, class_name: 'Church', foreign_key: 'parent_id'

  before_save :default_values
  def default_values
    self.development ||= 0
    self.security ||= 2
  end
end
