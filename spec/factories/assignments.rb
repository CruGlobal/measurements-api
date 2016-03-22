# frozen_string_literal: true
FactoryGirl.define do
  factory :assignment do
    gr_id { SecureRandom.uuid }
    person_id nil
    ministry_id nil
    role { Assignment::VALID_INPUT_ROLES.sample }
  end
end
