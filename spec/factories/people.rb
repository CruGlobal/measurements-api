FactoryBot.define do
  sequence(:random_name) { ("a".."z").to_a.shuffle[0, rand(3..12)].join.capitalize }
  factory :person do
    gr_id { SecureRandom.uuid }
    first_name { generate(:random_name) }
    last_name { generate(:random_name) }
    cas_guid { SecureRandom.uuid }
    cas_username { "#{first_name}.#{last_name}@example.com" }
  end
end
