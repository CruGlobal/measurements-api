# frozen_string_literal: true

FactoryGirl.define do
  factory :measurement_translation do
    measurement nil
    language "MyString"
    name "MyString"
    description "MyString"
    ministry nil
  end
end
