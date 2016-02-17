FactoryGirl.define do
  factory :ministry do
    ministry_id { SecureRandom.uuid }
    sequence(:name) { |n| "Test Ministry (#{n})" }
    min_code { ('A'..'Z').to_a.sample(3).join }
    area_code { Constants::AREAS.keys.sample }
    mccs { Constants::MCCS.sample(rand(5)) }
    default_mcc nil
    latitude { rand(-90.0..90.0) }
    longitude { rand(-180.0..180.0) }
    location_zoom { 1 + rand(12) }
    lmi_show []
    lmi_hide []
    hide_reports_tab { [true, false].sample }
    ministry_scope { [Constants::SCOPES.sample, nil].sample }
  end
end