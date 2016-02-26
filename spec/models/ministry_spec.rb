require 'rails_helper'

describe Ministry, type: :model do
  describe 'scope: inherited_ministries(person)' do
    before :all do
      @ministries = {}
      @ministries[:a] = FactoryGirl.create(:ministry, name: 'A')
      @ministries[:b] = FactoryGirl.create(:ministry, name: 'B')
      @ministries[:c] = FactoryGirl.create(:ministry, name: 'C')
      @ministries[:a1] = FactoryGirl.create(:ministry, name: 'A1', parent: @ministries[:a])
      @ministries[:a2] = FactoryGirl.create(:ministry, name: 'A2', parent: @ministries[:a])
      @ministries[:a3] = FactoryGirl.create(:ministry, name: 'A3', parent: @ministries[:a])
      @ministries[:a21] = FactoryGirl.create(:ministry, name: 'A21', parent: @ministries[:a2])
      @ministries[:a22] = FactoryGirl.create(:ministry, name: 'A22', parent: @ministries[:a2])
      @ministries[:a31] = FactoryGirl.create(:ministry, name: 'A31', parent: @ministries[:a3])
      @ministries[:c1] = FactoryGirl.create(:ministry, name: 'C1', parent: @ministries[:c])
      @ministries[:c11] = FactoryGirl.create(:ministry, name: 'C11', parent: @ministries[:c1])
      @ministries[:c12] = FactoryGirl.create(:ministry, name: 'C12', parent: @ministries[:c1])
      @ministries[:c121] = FactoryGirl.create(:ministry, name: 'C121', parent: @ministries[:c12])
      @ministries[:c122] = FactoryGirl.create(:ministry, name: 'C122', parent: @ministries[:c12])
      @ministries[:c123] = FactoryGirl.create(:ministry, name: 'C123', parent: @ministries[:c12])
    end

    after :all do
      Ministry.delete_all
    end

    let(:person) { FactoryGirl.create(:person) }
    let!(:ministries) { @ministries }
    subject { Ministry.inherited_ministries(person).to_a }

    context 'person with no assignments' do
      it 'returns an empty array' do
        expect(subject).to be_an Array
        expect(subject.length).to eq 0
      end
    end

    context 'person with member assignment' do
      let!(:assignments) { FactoryGirl.create(:assignment, person: person, ministry: ministries[:a2], role: :member) }
      it 'returns an empty array' do
        expect(subject).to be_an Array
        expect(subject.length).to eq 0
      end
    end

    context 'person with single leader assignment' do
      let!(:assignments) { FactoryGirl.create(:assignment, person: person, ministry: ministries[:a], role: :leader) }
      it 'returns an empty array' do
        expect(subject).to be_an Array
        expect(subject.length).to eq 7
      end
    end

    context 'person with single admin assignment' do
      let!(:assignments) { FactoryGirl.create(:assignment, person: person, ministry: ministries[:c1], role: :admin) }
      it 'returns an empty array' do
        expect(subject).to be_an Array
        expect(subject.length).to eq 6
      end
    end

    context 'person with multiple assignments' do
      let!(:assignments) do
        FactoryGirl.create(:assignment, person: person, ministry: ministries[:a1], role: :member)
        FactoryGirl.create(:assignment, person: person, ministry: ministries[:a2], role: :admin)
        FactoryGirl.create(:assignment, person: person, ministry: ministries[:b], role: :admin)
        FactoryGirl.create(:assignment, person: person, ministry: ministries[:c1], role: :leader)
        FactoryGirl.create(:assignment, person: person, ministry: ministries[:c12], role: :admin)
      end
      it 'returns an empty array' do
        expect(subject).to be_an Array
        expect(subject.length).to eq 10
      end
    end
  end
end
