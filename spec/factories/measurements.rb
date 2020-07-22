# frozen_string_literal: true

FactoryBot.define do
  factory :measurement do
    perm_link "lmi_total_custom_my_string"
    english "MyString"
    description "MyString"
    section "MyString"
    column "MyString"
    sort_order 1
    total_id { SecureRandom.uuid }
    local_id { SecureRandom.uuid }
    person_id { SecureRandom.uuid }
    stage false
    parent_id nil
    leader_only false
    supported_staff_only false
    mcc_filter nil
  end
end
