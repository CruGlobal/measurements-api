# frozen_string_literal: true
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

  context '.person_for_gr_id' do
    it 'finds a person for the gr_id if they exist already' do
      gr_id = SecureRandom.uuid
      person = create(:person, gr_id: gr_id)

      expect(Person.person_for_gr_id(gr_id)).to eq person
    end

    it 'creates the person from global registry if they do not exist yet' do
      gr_id = SecureRandom.uuid
      url = "#{ENV['GLOBAL_REGISTRY_URL']}/entities/#{gr_id}?entity_type=person"
      entity = { person: { id: gr_id, first_name: 'John' } }
      stub_request(:get, url).to_return(body: { entity: entity }.to_json)

      person = Person.person_for_gr_id(gr_id)

      expect(person).to_not be_new_record
      expect(person.gr_id).to eq gr_id
      expect(person.first_name).to eq 'John'
    end
  end
end
