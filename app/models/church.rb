class Church < ActiveRecord::Base
  belongs_to :parent, class_name: 'Church'
  has_many :children, class_name: 'Church', foreign_key: 'parent_id'
end
