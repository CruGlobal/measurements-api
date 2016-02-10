FactoryGirl.define do
  sequence(:random_name) { ('a'..'z').to_a.shuffle[0, 3 + rand(10)].join.capitalize }
  factory :person do
    person_id { SecureRandom.uuid }
    first_name { generate(:random_name) }
    last_name { generate(:random_name) }
    cas_guid { SecureRandom.uuid }
    cas_username { "#{first_name}.#{last_name}@example.com" }
  end
end
