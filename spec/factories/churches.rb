FactoryGirl.define do
  factory :church do
    church_id SecureRandom.hex(10)
    sequence(:name) { |n| "test church #{n}" }
    start_date 1.year.ago
    end_date 1.year.from_now
  end
end
