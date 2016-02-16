FactoryGirl.define do
  factory :church do
    sequence(:name) { |n| "test church #{n}" }
    start_date 1.year.ago
    end_date 1.year.from_now
    latitude { rand(-900..900) / 10.0 }
    longitude { rand(-1800..1800) / 10.0 }
    size { rand(1..100) }

    factory :church_with_ministry do
      association :target_area, factory: :ministry
    end
  end
end
