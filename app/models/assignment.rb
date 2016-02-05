class Assignment < ActiveRecord::Base
  enum role: { blocked: 0, former_member: 1, self_assigned: 2, member: 3,
               inherited_leader: 4, leader: 5, inherited_admin: 6, admin: 7 }

  belongs_to :person, foreign_key: :person_id, primary_key: :person_id
  belongs_to :ministry, foreign_key: :ministry_id, primary_key: :ministry_id
end
