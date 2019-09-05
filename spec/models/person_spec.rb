# frozen_string_literal: true

require "rails_helper"

describe Person, type: :model do
  describe "#inherited_assignment_for_ministry" do
    let(:person) { FactoryGirl.create(:person) }
    let(:grandparent) { FactoryGirl.create(:ministry) }
    let(:parent) { FactoryGirl.create(:ministry, parent: grandparent) }
    let(:ministry) { FactoryGirl.create(:ministry, parent: parent) }
    context "sub-ministry with inherited assignment" do
      let!(:admin) { FactoryGirl.create(:assignment, person: person, ministry: grandparent, role: :admin) }
      let!(:member) { FactoryGirl.create(:assignment, person: person, ministry: parent, role: :member) }

      subject { person.inherited_assignment_for_ministry(ministry) }
      it "has an inherited assignment" do
        is_expected.to be_an Assignment
        expect(subject.role).to eq "inherited_admin"
        expect(subject.person_id).to eq person.id
        expect(subject.ministry_id).to eq ministry.id
        expect(subject.gr_id).to be_nil
      end
    end

    context "sub-ministry with no assignments" do
    end
  end

  context ".person" do
    it "returns an existing person by cas guid" do
      person = create(:person, cas_guid: SecureRandom.uuid)
      expect(Person.person(person.cas_guid)).to eq person
    end

    it "fetches a person from global registry if one does not exist" do
      cas_guid = SecureRandom.uuid
      url = "#{ENV["GLOBAL_REGISTRY_URL"]}/entities?"\
        "fields=first_name,last_name,key_username,authentication,email_address.email&full_response=true"
      response = {entity: {person: {id: SecureRandom.uuid, first_name: "Joe"}}}
      request_stub = stub_request(:post, url).to_return(body: response.to_json)

      person = Person.person(cas_guid)

      expect(person).to_not be_new_record
      expect(person.first_name).to eq "Joe"
      expect(person.cas_guid).to eq cas_guid
      expect(request_stub).to have_been_requested
    end
  end

  context ".person_for_ea_guid" do
    it "returns an existing person by ea_guid" do
      person = create(:person, ea_guid: SecureRandom.uuid)
      expect(Person.person_for_ea_guid(person.ea_guid)).to eq person
    end

    it "fetches a person from global registry if one does not exist" do
      ea_guid = SecureRandom.uuid
      url = "#{ENV["GLOBAL_REGISTRY_URL"]}/entities?"\
        "fields=first_name,last_name,key_username,authentication,email_address.email&full_response=true"
      response = {entity: {person: {id: SecureRandom.uuid, first_name: "Joe"}}}
      request_stub = stub_request(:post, url).to_return(body: response.to_json)

      person = Person.person_for_ea_guid(ea_guid)

      expect(person).to_not be_new_record
      expect(person.first_name).to eq "Joe"
      expect(person.ea_guid).to eq ea_guid
      expect(request_stub).to have_been_requested
    end
  end

  context ".person_for_gr_id" do
    it "finds a person for the gr_id if they exist already" do
      gr_id = SecureRandom.uuid
      person = create(:person, gr_id: gr_id)

      expect(Person.person_for_gr_id(gr_id)).to eq person
    end

    it "creates the person from global registry if they do not exist yet" do
      gr_id = SecureRandom.uuid
      url = "#{ENV["GLOBAL_REGISTRY_URL"]}/entities/#{gr_id}?entity_type=person&"\
        "fields=first_name,last_name,key_username,authentication,email_address.email"
      entity = {person: {id: gr_id, first_name: "John"}}
      stub_request(:get, url).to_return(body: {entity: entity}.to_json)

      person = Person.person_for_gr_id(gr_id)

      expect(person).to_not be_new_record
      expect(person.gr_id).to eq gr_id
      expect(person.first_name).to eq "John"
    end
  end
end
