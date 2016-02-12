FactoryGirl.define do
  factory :assignment do
    assignment_id { SecureRandom.uuid }
    person_id nil
    ministry_id nil
    role 2
  end
end
