class Audit < ActiveRecord::Base
  enum audit_type: { new_story: 0, new_church: 1, new_training: 2, new_training_stage: 3,
                     new_target_city: 4, new_member: 5, new_subteam: 6 }
end
