FactoryGirl.define do
  factory :assignment do
    gr_id { SecureRandom.uuid }
    person_id nil
    ministry_id nil
    role { Assignment.roles.keys.sample }
  end
end
