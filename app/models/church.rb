class Church < ActiveRecord::Base
  belongs_to :parent, class_name: 'Church'
  has_many :children, class_name: 'Church', foreign_key: 'parent_id'

  belongs_to :created_by, class_name: 'Person'

  attr_accessor :parent_cluster_id

  before_save :default_values
  def default_values
    self.development ||= 1
    self.security ||= 2
  end

  enum security: { local_private_church: 0, private_church: 1, public_church: 2 }
  enum development: { target: 1, group_stage: 2, church: 3, multiplying_church: 5 }

  alias_attribute :ministry_id, :target_area_id
  alias_attribute :gr_id, :church_id

  def created_by_email
    created_by.try(:cas_username)
  end
end
