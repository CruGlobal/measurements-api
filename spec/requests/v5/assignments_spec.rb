# frozen_string_literal: true

require "rails_helper"

RSpec.describe "V5::Assignments", type: :request do # rubocop:disable Metrics/BlockLength
  before :all do
    @ministries = FactoryBot.create(:ministry_hierarchy)
  end
  after :all do
    Ministry.delete_all
    @ministries = nil
  end
  let!(:ministries) { @ministries }
  let(:person) { FactoryBot.create(:person) }
  let(:json) { JSON.parse(response.body) }

  describe "GET /v5/assignments" do
    context "as a user without assignments" do
      it "responds successfully with an empty array" do
        get "/v5/assignments", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

        expect(response).to be_successful
        expect(json).to be_an(Array).and be_empty
      end
    end

    context "as a member" do
      let!(:assignments) do
        [FactoryBot.create(:assignment, person: person, ministry: ministries[:a22], role: :member),
         FactoryBot.create(:assignment, person: person, ministry: ministries[:c12], role: :member),]
      end

      it "responds successfully with assignments" do
        get "/v5/assignments", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

        expect(response).to be_successful
        expect(json).to contain_exactly(a_hash_including("id" => assignments[1].gr_id, "team_role" => "member"),
          a_hash_including("id" => assignments[0].gr_id, "team_role" => "member"))
      end
    end

    context "as a leader" do
      let!(:assignment) do
        FactoryBot.create(:assignment, person: person, ministry: ministries[:a2], role: :leader)
      end

      it "responds successfully with assignments" do
        get "/v5/assignments", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

        expect(response).to be_successful
        expect(json).to contain_exactly(
          a_hash_including("id" => assignment.gr_id, "team_role" => "leader").and(include("sub_ministries"))
        )
        expect(json.first["sub_ministries"]).to all(include("team_role" => "inherited_leader"))
      end
    end

    context "as user with mixed roles" do
      let!(:assignments) do
        [FactoryBot.create(:assignment, person: person, ministry: ministries[:a], role: :leader),
         FactoryBot.create(:assignment, person: person, ministry: ministries[:a2], role: :member),
         FactoryBot.create(:assignment, person: person, ministry: ministries[:a3], role: :admin),]
      end

      it "responds successfully with assignments" do
        get "/v5/assignments", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

        expect(response).to be_successful
        expect(json).to contain_exactly(
          a_hash_including("id" => assignments[0].gr_id, "team_role" => "leader").and(include("sub_ministries")),
          a_hash_including("id" => assignments[1].gr_id, "team_role" => "member").and(exclude("sub_ministries")),
          a_hash_including("id" => assignments[2].gr_id, "team_role" => "admin").and(include("sub_ministries"))
        )
      end
    end
  end

  describe "GET /v5/assignments/:id" do
    context "unknown assignment" do
      it "responds with an HTTP 401" do
        get "/v5/assignments/#{SecureRandom.uuid}", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

        expect(response).to_not be_successful
        expect(response).to have_http_status(401)
        expect(json.keys).to contain_exactly("reason")
      end
    end

    context "as a member" do
      let!(:assignment) do
        FactoryBot.create(:assignment, person: person, ministry: ministries[:c12], role: :member,
                                        gr_id: SecureRandom.uuid)
      end
      context "get my own assignment" do
        it "responds successfully with my assignment" do
          get "/v5/assignments/#{assignment.gr_id}",
            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status 200
          expect(json).to include("id" => assignment.gr_id, "team_role" => "member",
                                  "ministry_id" => ministries[:c12].gr_id).and(exclude("sub_ministries"))
        end
      end

      context "get someone else's assignment" do
        it "responds with an HTTP 401" do
          get "/v5/assignments/#{assignment.gr_id}", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

          expect(response).to_not be_successful
          expect(response).to have_http_status(401)
          expect(json.keys).to contain_exactly("reason")
        end
      end
    end

    context "as a leader" do
      let!(:assignment) do
        FactoryBot.create(:assignment, person: person, ministry: ministries[:c12], role: :leader,
                                        gr_id: SecureRandom.uuid)
      end
      context "get my own assignment" do
        it "responds successfully with my assignment" do
          get "/v5/assignments/#{assignment.gr_id}",
            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status 200
          expect(json).to include("id" => assignment.gr_id, "team_role" => "leader",
                                  "ministry_id" => ministries[:c12].gr_id).and(include("sub_ministries"))
        end
      end

      context "get assignment of member on same ministry" do
        let(:member) { FactoryBot.create(:person) }
        let!(:member_assignment) do
          FactoryBot.create(:assignment, person: member, ministry: ministries[:c12],
                                          role: :member, gr_id: SecureRandom.uuid)
        end
        it "responds successfully with the assignment" do
          get "/v5/assignments/#{member_assignment.gr_id}",
            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status 200
          expect(json).to include("id" => member_assignment.gr_id, "team_role" => "member",
                                  "ministry_id" => ministries[:c12].gr_id).and(exclude("sub_ministries"))
        end
      end

      context "get assignment of member on sub-ministry" do
        let(:member) { FactoryBot.create(:person) }
        let!(:member_assignment) do
          FactoryBot.create(:assignment, person: member, ministry: ministries[:c121],
                                          role: :member, gr_id: SecureRandom.uuid)
        end
        it "responds successfully with the assignment" do
          get "/v5/assignments/#{member_assignment.gr_id}",
            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status 200
          expect(json).to include("id" => member_assignment.gr_id, "team_role" => "member",
                                  "ministry_id" => ministries[:c121].gr_id).and(exclude("sub_ministries"))
        end
      end
    end
  end

  describe "POST /v5/assignments" do
    context "as a user with no assignment" do
      context "create a self-assigned assignment" do
        let(:attributes) { {person_id: person.gr_id, ministry_id: ministries[:c1].gr_id, team_role: "self_assigned"} }
        let(:assignment) do
          FactoryBot.build(:assignment, person: person, ministry: ministries[:c1], role: "self_assigned")
        end
        let!(:request_stub) { gr_create_assignment_request(assignment) }

        it "responds successfully with new assignment" do
          post "/v5/assignments", params: attributes,
                                  headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status 201
          expect(request_stub).to have_been_requested
          expect(json).to include("ministry_id" => attributes[:ministry_id], "team_role" => attributes[:team_role])
            .and(include("id"))
          expect(json["id"]).to be_uuid
        end
      end

      context "create an assignment for someone else" do
        let(:other) { FactoryBot.create(:person) }
        let(:attributes) { {person_id: other.gr_id, ministry_id: ministries[:c12].gr_id, team_role: "self_assigned"} }

        it "responds with HTTP 400" do
          post "/v5/assignments", params: attributes,
                                  headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to_not be_successful
          expect(response).to have_http_status 400
        end
      end
    end

    context "as a leader" do
      let!(:assignment) { FactoryBot.create(:assignment, person: person, ministry: ministries[:a2], role: :leader) }

      context "self assign to sub ministry" do
        let(:attributes) do
          {person_id: person.gr_id, ministry_id: ministries[:a22].gr_id,
           team_role: "self_assigned",}
        end

        it "responds with HTTP 400" do
          post "/v5/assignments", params: attributes,
                                  headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to_not be_successful
          expect(response).to have_http_status 400
        end
      end

      context "self assign to different ministry" do
        let(:attributes) do
          {person_id: person.gr_id, ministry_id: ministries[:c1].gr_id, team_role: "self_assigned"}
        end
        let(:new_assignment) do
          FactoryBot.build(:assignment, person: person, ministry: ministries[:c1], role: "self_assigned")
        end
        let!(:request_stub) { gr_create_assignment_request(new_assignment) }

        it "responds successfully with new assignment" do
          post "/v5/assignments", params: attributes,
                                  headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status 201
          expect(request_stub).to have_been_requested
          expect(json).to include("ministry_id" => attributes[:ministry_id], "team_role" => attributes[:team_role])
            .and(include("id"))
          expect(json["id"]).to be_uuid
        end
      end

      context "create assignment for another user by person_id" do
        let(:other) { FactoryBot.create(:person) }
        let(:attributes) do
          {person_id: other.gr_id, ministry_id: ministries[:a22].gr_id, team_role: "admin"}
        end
        let(:new_assignment) do
          FactoryBot.build(:assignment, person: other, ministry: ministries[:a22], role: "admin")
        end
        let!(:request_stub) { gr_create_assignment_request(new_assignment) }

        it "responds successfully with new assignment" do
          post "/v5/assignments", params: attributes,
                                  headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status 201
          expect(request_stub).to have_been_requested
          expect(json).to include("ministry_id" => attributes[:ministry_id], "team_role" => attributes[:team_role])
            .and(include("id"))
          expect(json["id"]).to be_uuid
        end
      end

      context "create assignment for another user by username when they exist in GR" do
        let(:other) { FactoryBot.build(:person) }
        let(:attributes) do
          {username: other.cas_username, ministry_id: ministries[:a22].gr_id, team_role: "member"}
        end
        let!(:request_stub) { gr_person_request_by_username(other) }
        let(:new_assignment) do
          FactoryBot.build(:assignment, person: other, ministry: ministries[:a22], role: "member")
        end
        let!(:assignment_request_stub) { gr_create_assignment_request(new_assignment) }

        it "responds successfully with new assignment" do
          post "/v5/assignments", params: attributes,
                                  headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status 201
          expect(request_stub).to have_been_requested
          expect(assignment_request_stub).to have_been_requested
          expect(json).to include("ministry_id" => attributes[:ministry_id], "team_role" => attributes[:team_role])
            .and(include("id"))
          expect(json["id"]).to be_uuid
        end
      end

      context "create assignment for another user by username when they do not exist in GR" do
        let(:other) { FactoryBot.build(:person, email: "j@t.co", preferred_name: "Jo") }
        let(:attributes) do
          {username: other.cas_username, ministry_id: ministries[:a22].gr_id,
           team_role: "member", first_name: other.first_name,
           last_name: other.last_name, email: other.email,
           preferred_name: other.preferred_name,}
        end
        let(:new_assignment) do
          FactoryBot.build(:assignment, person: other, ministry: ministries[:a22], role: "member")
        end
        let!(:assignment_request_stub) { gr_create_assignment_request(new_assignment) }
        let!(:find_person_stub) do
          gr_person_request_by_username_not_found(other.cas_username)
        end
        let!(:create_person_stub) { gr_create_person_request(other) }

        it "responds successfully with new assignment" do
          expect {
            post "/v5/assignments", params: attributes,
                                    headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}
          }.to change(Person, :count).by(1)

          expect(response).to be_successful
          expect(response).to have_http_status 201
          expect(find_person_stub).to have_been_requested
          expect(create_person_stub).to have_been_requested
          expect(assignment_request_stub).to have_been_requested
          expect(json).to include("ministry_id" => attributes[:ministry_id], "team_role" => attributes[:team_role])
            .and(include("id"))
          expect(json["id"]).to be_uuid
        end
      end

      context "create assignment for another existing user on different ministry" do
        let(:other) { create(:person) }
        let(:attributes) do
          {person_id: other.gr_id, ministry_id: ministries[:c1].gr_id,
           team_role: "blocked",}
        end

        it "responds with HTTP 400" do
          post "/v5/assignments", params: attributes,
                                  headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to_not be_successful
          expect(response).to have_http_status 400
        end
      end
    end
  end

  describe "PUT /v5/assignments/:id" do
    context "as a user with no assignment" do
      context "update unknown assignment" do
        it "responds with HTTP 401" do
          put "/v5/assignments/#{SecureRandom.uuid}", params: {team_role: "member"},
                                                      headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

          expect(response).to_not be_successful
          expect(response).to have_http_status 401
        end
      end

      context "update an assignment" do
        let(:other) { FactoryBot.build(:person) }
        let(:assignment) do
          FactoryBot.create(:assignment, person: other, ministry: ministries[:a2], role: :member,
                                          gr_id: SecureRandom.uuid)
        end
        it "responds with HTTP 401" do
          put "/v5/assignments/#{assignment.gr_id}", params: {team_role: "member"},
                                                     headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

          expect(response).to_not be_successful
          expect(response).to have_http_status 401
        end
      end
    end

    context "as a member" do
      let(:assignment) do
        FactoryBot.create(:assignment, person: person, ministry: ministries[:a2], role: :member,
                                        gr_id: SecureRandom.uuid)
      end
      context "update your assignment" do
        it "responds with HTTP 401" do
          put "/v5/assignments/#{assignment.gr_id}",
            params: {team_role: "leader"},
            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to_not be_successful
          expect(response).to have_http_status 401
        end
      end
    end

    context "as a leader" do
      let!(:assignment) do
        FactoryBot.create(:assignment, person: person, ministry: ministries[:a2], role: :leader,
                                        gr_id: SecureRandom.uuid)
      end
      context "update your assignment" do
        it "responds with HTTP 400" do
          put "/v5/assignments/#{assignment.gr_id}",
            params: {team_role: "admin"},
            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to_not be_successful
          expect(response).to have_http_status 400
        end
      end

      context "update a members assignment" do
        let(:other) { FactoryBot.create(:person) }
        let!(:member_assignment) do
          FactoryBot.create(:assignment, person: other, ministry: ministries[:a21],
                                          role: :member, gr_id: SecureRandom.uuid)
        end
        context "to a valid input role" do
          let!(:request_stub) { gr_update_assignment_request(member_assignment) }
          it "responds successfully with updated assignment" do
            put "/v5/assignments/#{member_assignment.gr_id}",
              params: {team_role: "leader"},
              headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

            expect(response).to be_successful
            expect(response).to have_http_status 200
            expect(json).to include("ministry_id" => ministries[:a21].gr_id, "team_role" => "leader",
                                    "id" => member_assignment.gr_id)
            expect(request_stub).to have_been_requested
          end
        end

        context "to an inherited role" do
          it "responds with HTTP 400" do
            put "/v5/assignments/#{member_assignment.gr_id}",
              params: {team_role: "inherited_leader"},
              headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

            expect(response).to_not be_successful
            expect(response).to have_http_status 400
          end
        end
      end
    end
  end
end
