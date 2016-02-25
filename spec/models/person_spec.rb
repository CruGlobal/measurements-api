require 'rails_helper'

describe Person, type: :model do
  describe '#inherited_assignment_for_ministry' do
    let(:person) { FactoryGirl.create(:person) }
    let(:grandparent) { FactoryGirl.create(:ministry) }
    let(:parent) { FactoryGirl.create(:ministry, parent: grandparent) }
    let(:ministry) { FactoryGirl.create(:ministry, parent: parent) }
    context 'sub-ministry with inherited assignment' do
      let!(:admin) { FactoryGirl.create(:assignment, person: person, ministry: grandparent, role: :admin) }
      let!(:member) { FactoryGirl.create(:assignment, person: person, ministry: parent, role: :member) }

      subject { person.inherited_assignment_for_ministry(ministry) }
      it 'has an inherited assignment' do
        is_expected.to be_an Assignment
        expect(subject.role).to eq 'inherited_admin'
        expect(subject.person_id).to eq person.id
        expect(subject.ministry_id).to eq ministry.id
        expect(subject.gr_id).to be_nil
      end
    end

    context 'sub-ministry with no assignments' do
    end
  end

  describe '#inherited_leader_ministries' do
    let(:person) { FactoryGirl.create(:person) }
    let!(:a) { FactoryGirl.create(:ministry, name: 'A') }
    let!(:b) { FactoryGirl.create(:ministry, name: 'B') }
    let!(:c) { FactoryGirl.create(:ministry, name: 'C') }
    let!(:a1) { FactoryGirl.create(:ministry, name: 'A1', parent: a) }
    let!(:a2) { FactoryGirl.create(:ministry, name: 'A2', parent: a) }
    let!(:a3) { FactoryGirl.create(:ministry, name: 'A3', parent: a) }
    let!(:a21) { FactoryGirl.create(:ministry, name: 'A21', parent: a2) }
    let!(:a22) { FactoryGirl.create(:ministry, name: 'A22', parent: a2) }
    let!(:a31) { FactoryGirl.create(:ministry, name: 'A31', parent: a3) }
    let!(:c1) { FactoryGirl.create(:ministry, name: 'C1', parent: c) }
    let!(:c11) { FactoryGirl.create(:ministry, name: 'C11', parent: c1) }
    let!(:c12) { FactoryGirl.create(:ministry, name: 'C12', parent: c1) }
    let!(:c121) { FactoryGirl.create(:ministry, name: 'C121', parent: c12) }
    let!(:c122) { FactoryGirl.create(:ministry, name: 'C122', parent: c12) }
    let!(:c123) { FactoryGirl.create(:ministry, name: 'C123', parent: c12) }
    context 'multiple assignments' do
      let!(:assignments) do
        FactoryGirl.create(:assignment, person: person, ministry: a1, role: :member)
        FactoryGirl.create(:assignment, person: person, ministry: a2, role: :admin)
        FactoryGirl.create(:assignment, person: person, ministry: b, role: :admin)
        FactoryGirl.create(:assignment, person: person, ministry: c1, role: :leader)
        FactoryGirl.create(:assignment, person: person, ministry: c12, role: :admin)
      end

      it 'works' do
        ministries = person.inherited_leader_ministries
        expect(ministries).to_not be_nil
        expect(ministries.length).to eq 10
      end
    end
  end
end
