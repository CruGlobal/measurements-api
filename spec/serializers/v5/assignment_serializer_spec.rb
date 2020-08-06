# frozen_string_literal: true

require "rails_helper"

RSpec.describe V5::AssignmentSerializer do
  before :all do
    @ministries = FactoryBot.create(:ministry_hierarchy)
  end
  after :all do
    Ministry.delete_all
    @ministries = nil
  end
  let!(:ministries) { @ministries }

  describe "an assignment" do
    let(:person) { FactoryBot.create(:person) }
    let(:serializer) { V5::AssignmentSerializer.new(assignment) }
    let(:serialization) { ActiveModelSerializers::Adapter.create(serializer) }
    let(:json) { serialization.as_json }

    context "leader assignment" do
      let(:assignment) do
        FactoryBot.create(:assignment, person: person, ministry: ministries[:c1], role: :leader,
                                       gr_id: SecureRandom.uuid)
      end

      it "has attributes" do
        expect(json[:id]).to be_uuid.and(match assignment.gr_id)
        expect(json[:team_role]).to be_a(String).and(match assignment.role.to_s)
        expect(json[:parent_id]).to be_uuid.and(match ministries[:c].gr_id)
        expect(json[:content_locales]).to be_an(Array)
        expect(json[:location]).to be_a(Hash)
        expect(json[:location].keys).to contain_exactly(:latitude, :longitude)
        expect(json[:mccs]).to be_an(Array)
        expect(json[:name]).to be_a(String).and(match ministries[:c1].name)
        expect(json[:lmi_show]).to be_an(Array)
        expect(json[:lmi_hide]).to be_an(Array)
      end

      it "has sub_ministries" do
        assignments = flatten_assignment(json)
        expect(assignments).to be_an Array
        expect(assignments.length).to eq 6
        expect(assignments).to contain_exactly(
          a_hash_including(ministry_id: ministries[:c1].gr_id, team_role: "leader")
            .and(include(:sub_ministries)),
          a_hash_including(ministry_id: ministries[:c11].gr_id, team_role: "inherited_leader")
            .and(exclude(:sub_ministries)),
          a_hash_including(ministry_id: ministries[:c12].gr_id, team_role: "inherited_leader")
            .and(include(:sub_ministries)),
          a_hash_including(ministry_id: ministries[:c121].gr_id, team_role: "inherited_leader")
            .and(exclude(:sub_ministries)),
          a_hash_including(ministry_id: ministries[:c122].gr_id, team_role: "inherited_leader")
            .and(exclude(:sub_ministries)),
          a_hash_including(ministry_id: ministries[:c123].gr_id, team_role: "inherited_leader")
            .and(exclude(:sub_ministries))
        )
      end

      context "with sub-assignments" do
        let!(:assignments) do
          [FactoryBot.create(:assignment, person: person, ministry: ministries[:c11], role: :admin,
                                          gr_id: SecureRandom.uuid),
           FactoryBot.create(:assignment, person: person, ministry: ministries[:c12], role: :member,
                                          gr_id: SecureRandom.uuid),]
        end

        it "has sub_ministries with inherited assignments" do
          expect(json[:sub_ministries]).to be_an(Array)
          expect(json[:sub_ministries].length).to eq 2
          roles = json[:sub_ministries].collect { |v| v[:team_role] }
          expect(roles).to contain_exactly("inherited_leader", "inherited_leader")
        end
      end
    end

    context "member assignment" do
      let(:assignment) do
        FactoryBot.create(:assignment, person: person, ministry: ministries[:c12], role: :member,
                                       gr_id: SecureRandom.uuid)
      end

      it "does not have sub_ministries" do
        expect(json).to_not include(:sub_ministries)
      end
    end
  end
end
