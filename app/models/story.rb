class Story < ActiveRecord::Base
  enum privacy: { everyone: 0, team_only: 1 }
  enum state: { draft: 0, published: 1, removed: 2 }

  belongs_to :ministry
  belongs_to :created_by, class_name: 'Person'
  belongs_to :church
  belongs_to :training

  mount_uploader :image, ImageUploader
end
