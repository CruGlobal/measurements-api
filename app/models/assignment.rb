class Assignment < ActiveRecord::Base
  enum role: [blocked: 0, former_member: 1, self_assigned: 2, member: 3,
              inherited_admin: 4, admin: 5, inherited_leader: 6, leader: 7]
end
