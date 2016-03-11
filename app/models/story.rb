class Story < ActiveRecord::Base
  enum privacy: { public: 0, team_only: 1 }
  enum state: { draft: 0, published: 1, removed: 2 }

  belongs_to :church
  belongs_to :training
end
