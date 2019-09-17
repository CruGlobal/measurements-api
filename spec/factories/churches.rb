# frozen_string_literal: true

FactoryGirl.define do
  factory :church do
    sequence(:name) { |n| "test church #{n}" }
    start_date 1.year.ago
    end_date 1.year.from_now
    latitude do
      # we want our values to be
      l = rand(-90.0..90.0)
      l == 0.0 ? 0.1 : l
    end
    longitude do
      l = rand(-180.0..180.0)
      l == 0.0 ? 0.1 : l
    end
    size { rand(1..100) }
    security 2
    development 1

    factory :church_with_ministry do
      association :ministry
    end
  end
end
