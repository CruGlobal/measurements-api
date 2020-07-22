# frozen_string_literal: true

FactoryBot.define do
  #     a         b        c
  #  / |  \                |
  # a1 a2 a3               c1
  #   /  \  \            /    \
  # a21 a22 a31        c11    c12
  #                         /  |  \
  #                     c121 c122 c123
  factory :ministry_hierarchy, class: Hash do
    skip_create

    a { FactoryBot.create(:ministry, name: "A") }
    b { FactoryBot.create(:ministry, name: "B") }
    c { FactoryBot.create(:ministry, name: "C") }
    a1 { FactoryBot.create(:ministry, name: "A1", parent: a) }
    a2 { FactoryBot.create(:ministry, name: "A2", parent: a) }
    a3 { FactoryBot.create(:ministry, name: "A3", parent: a) }
    a21 { FactoryBot.create(:ministry, name: "A21", parent: a2) }
    a22 { FactoryBot.create(:ministry, name: "A22", parent: a2) }
    a31 { FactoryBot.create(:ministry, name: "A31", parent: a3) }
    c1 { FactoryBot.create(:ministry, name: "C1", parent: c) }
    c11 { FactoryBot.create(:ministry, name: "C11", parent: c1) }
    c12 { FactoryBot.create(:ministry, name: "C12", parent: c1) }
    c121 { FactoryBot.create(:ministry, name: "C121", parent: c12) }
    c122 { FactoryBot.create(:ministry, name: "C122", parent: c12) }
    c123 { FactoryBot.create(:ministry, name: "C123", parent: c12) }

    initialize_with { attributes }
  end
end
