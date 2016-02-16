FactoryGirl.define do
  factory :church do
    sequence(:name) { |n| "test church #{n}" }
    start_date 1.year.ago
    end_date 1.year.from_now
    latitude do
      # we want our values to be
      l = rand(-900..900) / 10.0
      l == 0.0 ? 0.1 : l
    end
    longitude do
      l = rand(-1800..1800) / 10.0
      l == 0.0 ? 0.1 : l
    end
    size { rand(1..100) }
    security 2
    development 1

    factory :church_with_ministry do
      association :target_area, factory: :ministry
    end
  end
end
