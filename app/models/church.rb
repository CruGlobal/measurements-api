class Church < ActiveRecord::Base
  belongs_to :parent, class_name: 'Church'
  has_many :children, class_name: 'Church', foreign_key: 'parent_id'

  before_save :default_values
  def default_values
    self.development ||= 1
    self.security ||= 2
  end

  enum security: { local_private_church: 0, private_church: 1, public_church: 2 }
  enum development: { target: 1, group_stage: 2, church: 3, multiplying_church: 5 }
end
