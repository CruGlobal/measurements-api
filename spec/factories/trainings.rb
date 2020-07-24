FactoryBot.define do
  factory :training do
    ministry { nil }
    sequence(:name) { |n| "test training #{n}" }
    date { "2016-02-19 17:19:10" }
    type { "" }
    mcc { "asd" }
    latitude { "9.99" }
    longitude { "9.99" }
    created_by { nil }
  end
end
