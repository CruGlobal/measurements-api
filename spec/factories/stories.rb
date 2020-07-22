# frozen_string_literal: true

FactoryBot.define do
  factory :story do
    sequence(:title) { |n| "Test Story (#{n})" }
    content "Bacon ipsum dolor amet tail turkey strip steak jerky, picanha rump t-bone corned beef kevin shankle " \
            "bacon boudin leberkas pork flank. Short loin filet mignon cupim leberkas swine turducken pork pork " \
            "chop tail fatback t-bone landjaeger bresaola ham. Sirloin biltong ball tip tenderloin beef pig " \
            "turducken. Ham tri-tip turkey boudin, pig bresaola beef pancetta short ribs bacon ham hock. " \
            "Frankfurter pork chop picanha corned beef. Leberkas salami shankle short loin shoulder, ribeye ham " \
            "biltong pancetta"
    mcc { Ministry::MCCS.sample }
    language { %w[en-US en-GB fr-FR nl-NL hi-IN pt-BR es-CR].sample }
    privacy :everyone
    state :published
    created_by_id nil
    ministry_id nil
    training_id nil
    church_id nil
    latitude { rand(-90.0..90.0) }
    longitude { rand(-180.0..180.0) }
  end
end
