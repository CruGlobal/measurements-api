FactoryGirl.define do
  factory :church do
    sequence(:name) { |n| "test church #{n}" }
    start_date 1.year.ago
    end_date 1.year.from_now
  end
end
