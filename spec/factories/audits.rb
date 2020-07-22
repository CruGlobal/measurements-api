# frozen_string_literal: true

FactoryBot.define do
  factory :audit do
    person_id ""
    ministry_id ""
    message "MyString"
    audit_type :new_story
    ministry_name "MyString"
  end
end
