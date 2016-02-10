FactoryGirl.define do
  factory :church do
    sequence(:name) { |n| "test church #{n}" }
    start_date 1.year.ago
    end_date 1.year.from_now
    latitude { rand(-90..90) }
    longitude { rand(-180..180) }
    size { rand(1..100) }
  end
end
