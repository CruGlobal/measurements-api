# frozen_string_literal: true

FactoryBot.define do
  factory :ministry do
    gr_id { SecureRandom.uuid }
    sequence(:name) { |n| "Test Ministry (#{n})" }
    min_code { ("A".."Z").to_a.sample(3).join }
    mccs { Ministry::MCCS.sample(rand(5)) }
    default_mcc nil
    latitude { rand(-90.0..90.0) }
    longitude { rand(-180.0..180.0) }
    location_zoom { rand(1..12) }
    lmi_show []
    lmi_hide []
    hide_reports_tab { [true, false].sample }
    ministry_scope { [Ministry::SCOPES.sample, nil].sample }
  end
end
