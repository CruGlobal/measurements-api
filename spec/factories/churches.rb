FactoryGirl.define do
  factory :church do
    church_id { SecureRandom.uuid }
    sequence(:name) { |n| "test church #{n}" }
    start_date 1.year.ago
    end_date 1.year.from_now
  end
end
