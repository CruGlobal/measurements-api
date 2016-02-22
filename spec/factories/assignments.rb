FactoryGirl.define do
  factory :assignment do
    gr_id { SecureRandom.uuid }
    person_id nil
    ministry_id nil
    role :self_assigned
  end
end
