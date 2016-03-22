# frozen_string_literal: true
FactoryGirl.define do
  #     a         b        c
  #  / |  \                |
  # a1 a2 a3               c1
  #   /  \  \            /    \
  # a21 a22 a31        c11    c12
  #                         /  |  \
  #                     c121 c122 c123
  factory :ministry_hierarchy, class: Hash do
    skip_create

    a { FactoryGirl.create(:ministry, name: 'A') }
    b { FactoryGirl.create(:ministry, name: 'B') }
    c { FactoryGirl.create(:ministry, name: 'C') }
    a1 { FactoryGirl.create(:ministry, name: 'A1', parent: a) }
    a2 { FactoryGirl.create(:ministry, name: 'A2', parent: a) }
    a3 { FactoryGirl.create(:ministry, name: 'A3', parent: a) }
    a21 { FactoryGirl.create(:ministry, name: 'A21', parent: a2) }
    a22 { FactoryGirl.create(:ministry, name: 'A22', parent: a2) }
    a31 { FactoryGirl.create(:ministry, name: 'A31', parent: a3) }
    c1 { FactoryGirl.create(:ministry, name: 'C1', parent: c) }
    c11 { FactoryGirl.create(:ministry, name: 'C11', parent: c1) }
    c12 { FactoryGirl.create(:ministry, name: 'C12', parent: c1) }
    c121 { FactoryGirl.create(:ministry, name: 'C121', parent: c12) }
    c122 { FactoryGirl.create(:ministry, name: 'C122', parent: c12) }
    c123 { FactoryGirl.create(:ministry, name: 'C123', parent: c12) }

    initialize_with { attributes }
  end
end
