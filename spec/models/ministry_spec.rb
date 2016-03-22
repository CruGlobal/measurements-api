# frozen_string_literal: true
require 'rails_helper'

describe Ministry, type: :model do
  before :all do
    @ministries = FactoryGirl.create(:ministry_hierarchy)
  end
  after :all do
    Ministry.delete_all
  end
  let!(:ministries) { @ministries }

  describe 'scope: inherited_ministries(person)' do
    let(:person) { FactoryGirl.create(:person) }
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

  describe '#team_members' do
    let(:team_members) do
      team_members = {}
      team_members[:A] = FactoryGirl.create(:person)
      team_members[:B] = FactoryGirl.create(:person)
      team_members[:C] = FactoryGirl.create(:person)
      team_members[:D] = FactoryGirl.create(:person)
      team_members[:E] = FactoryGirl.create(:person)
      team_members
    end
    let!(:assignments) do
      FactoryGirl.create(:assignment, person: team_members[:A], ministry: ministries[:c1], role: :leader)
      FactoryGirl.create(:assignment, person: team_members[:A], ministry: ministries[:c12], role: :admin)
      FactoryGirl.create(:assignment, person: team_members[:B], ministry: ministries[:c], role: :admin)
      FactoryGirl.create(:assignment, person: team_members[:B], ministry: ministries[:c1], role: :leader)
      FactoryGirl.create(:assignment, person: team_members[:B], ministry: ministries[:c12], role: :member)
      FactoryGirl.create(:assignment, person: team_members[:C], ministry: ministries[:c1], role: :member)
      FactoryGirl.create(:assignment, person: team_members[:C], ministry: ministries[:c123], role: :leader)
      FactoryGirl.create(:assignment, person: team_members[:D], ministry: ministries[:c], role: :blocked)
      FactoryGirl.create(:assignment, person: team_members[:D], ministry: ministries[:c12], role: :member)
      FactoryGirl.create(:assignment, person: team_members[:E], ministry: ministries[:c11], role: :admin)
    end

    describe 'for ministry `C`' do
      subject { ministries[:c].team_members }

      it 'has team members' do
        expect(subject.length).to eq 2
        assignments = subject.collect { |member| [member.person_id, member.role] }
        expect(assignments).to include([team_members[:B].id, :admin.to_s], [team_members[:D].id, :blocked.to_s])
      end
    end

    describe 'for ministry `C1`' do
      subject { ministries[:c1].team_members }

      it 'has team members' do
        expect(subject.length).to eq 3
        assignments = subject.collect { |member| [member.person_id, member.role] }
        expect(assignments).to include([team_members[:A].id, :leader.to_s],
                                       [team_members[:B].id, :leader.to_s],
                                       [team_members[:C].id, :member.to_s])
      end
    end

    describe 'for ministry `C11`' do
      subject { ministries[:c11].team_members }

      it 'has team members' do
        expect(subject.length).to eq 3
        assignments = subject.collect { |member| [member.person_id, member.role] }
        expect(assignments).to include([team_members[:A].id, :inherited_leader.to_s],
                                       [team_members[:B].id, :inherited_admin.to_s],
                                       [team_members[:E].id, :admin.to_s])
      end
    end

    describe 'for ministry `C12`' do
      subject { ministries[:c12].team_members }

      it 'has team members' do
        expect(subject.length).to eq 3
        assignments = subject.collect { |member| [member.person_id, member.role] }
        expect(assignments).to include([team_members[:A].id, :admin.to_s],
                                       [team_members[:B].id, :member.to_s],
                                       [team_members[:D].id, :member.to_s])
      end
    end

    describe 'for ministry `C121`' do
      subject { ministries[:c121].team_members }

      it 'has team members' do
        expect(subject.length).to eq 2
        assignments = subject.collect { |member| [member.person_id, member.role] }
        expect(assignments).to include([team_members[:A].id, :inherited_admin.to_s],
                                       [team_members[:B].id, :inherited_admin.to_s])
      end
    end

    describe 'for ministry `C123`' do
      subject { ministries[:c123].team_members }

      it 'has team members' do
        expect(subject.length).to eq 3
        assignments = subject.collect { |member| [member.person_id, member.role] }
        expect(assignments).to include([team_members[:A].id, :inherited_admin.to_s],
                                       [team_members[:B].id, :inherited_admin.to_s],
                                       [team_members[:C].id, :leader.to_s])
      end
    end

    describe 'for ministry `A22`' do
      subject { ministries[:a22].team_members }

      it 'does not have team members' do
        expect(subject.length).to eq 0
      end
    end
  end

  context '.ministry' do
    it 'finds an existing ministry by gr_id if it exists' do
      gr_id = SecureRandom.uuid
      existing_ministry = create(:ministry, gr_id: gr_id)

      expect(Ministry.ministry(gr_id)).to eq existing_ministry
    end

    it 'retrieves a ministry from global registry if we do one for that gr_id' do
      ministry_gr_id = SecureRandom.uuid
      area_gr_id = SecureRandom.uuid
      url = "#{ENV['GLOBAL_REGISTRY_URL']}/entities/#{ministry_gr_id}"
      stub_request(:get, url).to_return(body: {
        entity: {
          ministry: {
            id: ministry_gr_id, name: 'Test',
            'area:relationship': {
              area: area_gr_id
            }
          }
        }
      }.to_json)
      area = create(:area)
      allow(Area).to receive(:for_gr_id).with(area_gr_id) { area }

      ministry = Ministry.ministry(ministry_gr_id)

      expect(ministry).to_not be_new_record
      expect(ministry.gr_id).to eq ministry_gr_id
      expect(ministry.name).to eq 'Test'
      expect(ministry.area).to eq area
    end
  end

  context '.create_or_update_from_entity!' do
    it 'updates an existing ministry based on the entity' do
      ministry = create(:ministry)
      entity = {
        'ministry' => { 'id' => ministry.gr_id, 'name' => 'new name' }
      }

      Ministry.create_or_update_from_entity!(entity)

      expect(ministry.reload.name).to eq 'new name'
    end

    it 'creates a new ministry if none exists for entity id' do
      gr_id = SecureRandom.uuid
      entity = {
        'ministry' => { 'id' => gr_id, 'name' => 'name' }
      }

      expect do
        Ministry.create_or_update_from_entity!(entity)
      end.to change(Ministry, :count).by(1)

      expect(Ministry.last.name).to eq 'name'
      expect(Ministry.last.gr_id).to eq gr_id
    end
  end
end
