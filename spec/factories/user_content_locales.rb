FactoryBot.define do
  factory :user_content_locale do
    person_id { nil }
    ministry_id { nil }
    locale { %w[en-US en-GB fr-FR nl-NL hi-IN pt-BR es-CR].sample }
  end
end
