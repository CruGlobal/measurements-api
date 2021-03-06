# frozen_string_literal: true

require "rails_helper"

RSpec.describe "V5::Ministries", type: :request do
  describe "GET /v5/ministries" do
    let!(:ministries) do
      area = FactoryBot.create(:area, name: "Test Area", code: "TEST")
      ministries = []
      ministries << FactoryBot.create(:ministry, ministry_scope: "National", area: area)
      ministries << FactoryBot.create(:ministry, ministry_scope: nil)
      ministries << FactoryBot.create(:ministry, parent_id: ministries.sample.id, ministry_scope: "National Region",
                                                 area: area)
      ministries << FactoryBot.create(:ministry, parent_id: ministries.sample.id, ministry_scope: nil)
      ministries
    end

    it "responds with all ministries" do
      get "/v5/ministries", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}
      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json.length).to be ministries.length
    end

    # context 'with refresh=true' do
    #   it 'responds with HTTP 202 Accepted' do
    #     clear_uniqueness_locks
    #     expect do
    #       get '/v5/ministries', { refresh: true }, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"
    #       expect(response).to be_successful
    #       expect(response).to have_http_status(202)
    #     end.to change(GrSync::WithGrWorker.jobs, :size).by(1)
    #   end
    # end

    context "with whq_only=true" do
      it "responds with whq ministries" do
        get "/v5/ministries", params: {whq_only: 1},
                              headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}
        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json.length).to be 2
        expect(json[0].keys).to contain_exactly("ministry_id", "name", "min_code", "area_code", "area_name")
      end
    end
  end

  describe "GET /v5/ministries/:id" do
    let(:person) { FactoryBot.create(:person) }
    let(:ministry) { FactoryBot.create(:ministry) }

    context "without an assignment" do
      it "responds with HTTP 401" do
        get "/v5/ministries/#{ministry.gr_id}", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}
        expect(response).to have_http_status(401)
        json = JSON.parse(response.body)
        expect(json.keys).to contain_exactly("reason")
      end
    end

    context "with an admin or leader assignment" do
      let!(:assignment) do
        FactoryBot.create(:assignment, person_id: person.id, ministry_id: ministry.id,
                                       role: %i[admin leader].sample)
      end

      it "responds with the ministry details" do
        get "/v5/ministries/#{ministry.gr_id}",
          headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

        expect(response).to be_successful
        expect(response).to have_http_status(200)
        expect(response.body).to include_json(ministry_id: ministry.gr_id, min_code: ministry.min_code)
      end
    end

    context "with an inherited admin or leader assignment" do
      let(:sub_ministry) { FactoryBot.create(:ministry, parent: ministry) }
      let!(:assignment) do
        FactoryBot.create(:assignment, person: person, ministry: ministry,
                                       role: %i[admin leader].sample)
      end

      it "responds with the ministry details" do
        get "/v5/ministries/#{sub_ministry.gr_id}",
          headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

        expect(response).to be_successful
        expect(response).to have_http_status(200)
        expect(response.body).to include_json(ministry_id: sub_ministry.gr_id, min_code: sub_ministry.min_code)
      end
    end

    context "with a non admin/leader assignment" do
      let!(:assignment) do
        FactoryBot.create(:assignment,
          person_id: person.id,
          ministry_id: ministry.id,
          role: %i[blocked former_member self_assigned member].sample)
      end

      it "responds with HTTP 401" do
        get "/v5/ministries/#{ministry.gr_id}",
          headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}
        expect(response).to have_http_status(401)
        json = JSON.parse(response.body)
        expect(json.keys).to contain_exactly("reason")
      end
    end
  end

  describe "POST /v5/ministries" do
    context "create a ministry" do
      let(:person) { FactoryBot.create(:person) }
      context "with required attributes" do
        let(:ministry) { FactoryBot.build(:ministry) }
        let(:assignment) { build(:assignment, ministry: ministry, person: person) }
        let!(:gr_request_stub) { gr_create_ministry_request(ministry) }
        let!(:gr_assignment_stub) { gr_create_assignment_request(assignment) }
        it "responds successfully with the new ministry" do
          expect {
            post "/v5/ministries", params: ministry.attributes,
                                   headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

            expect(response).to be_successful
            expect(response).to have_http_status(201)
            expect(gr_request_stub).to have_been_requested
            json = JSON.parse(response.body).with_indifferent_access
            expect(json[:ministry_id]).to be_uuid.and(eq ministry.gr_id)

            assignment = person.assignment_for_ministry(json[:ministry_id])
            expect(assignment).to_not be_nil
            expect(assignment.leader_role?).to eq true
          }.to change { Ministry.count }.by(1)
        end
      end

      context "missing required attributes" do
        let(:ministry) { {name: nil, lmi_show: true, mccs: nil, ministry_scope: "Blah", hello: 123} }
        it "responds with HTTP 400" do
          post "/v5/ministries", params: ministry,
                                 headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to_not be_successful
          expect(response).to have_http_status(400)
          json = JSON.parse(response.body).with_indifferent_access
          expect(json.keys).to contain_exactly("name", "min_code")
        end
      end
    end

    context "create sub-ministry" do
      let(:person) { FactoryBot.create(:person) }
      let(:parent) { FactoryBot.create(:ministry) }
      let(:ministry) { FactoryBot.build(:ministry, parent: parent) }
      let(:attributes) { ministry.attributes.merge parent_id: parent.gr_id }

      context "as leader of parent ministry" do
        let!(:gr_request_stub) { gr_create_ministry_request(ministry) }
        let!(:assignment) do
          FactoryBot.create(:assignment, ministry: parent, person: person,
                                         role: %i[admin leader].sample)
        end
        let!(:new_admin_assignment) do
          build(:assignment, ministry: ministry, person: person, role: "admin")
        end
        let!(:gr_new_admin_assignment_stub) do
          gr_create_assignment_request(new_admin_assignment)
        end

        it "responds successfully with new ministry" do
          expect {
            post "/v5/ministries", params: attributes,
                                   headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

            expect(response).to be_successful
            expect(response).to have_http_status(201)
            expect(gr_request_stub).to have_been_requested
            expect(gr_new_admin_assignment_stub).to have_been_requested
            json = JSON.parse(response.body).with_indifferent_access
            expect(json[:ministry_id]).to be_uuid.and(eq ministry.gr_id)
            expect(json[:parent_id]).to be_uuid.and(eq parent.gr_id)

            sub_assignment = person.assignment_for_ministry(json[:ministry_id])
            expect(sub_assignment).to_not be_nil
            expect(sub_assignment.leader_role?).to eq true
          }.to change { Ministry.count }.by(1)
        end
      end

      context "as user with no role on parent ministry" do
        it "responds with HTTP 400" do
          post "/v5/ministries", params: attributes,
                                 headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to_not be_successful
          expect(response).to have_http_status(400)
          json = JSON.parse(response.body).with_indifferent_access
          expect(json.keys).to contain_exactly("parent_id")
        end
      end
    end
  end

  describe "PUT /v5/ministries/:id" do
    let(:person) { FactoryBot.create(:person) }
    context "unknown ministry" do
      let(:ministry) { FactoryBot.build(:ministry) }
      let!(:gr_request_stub) { gr_get_invalid_ministry_request(ministry) }

      it "responds with HTTP 401" do
        put "/v5/ministries/#{ministry.gr_id}",
          params: ministry.attributes,
          headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

        expect(gr_request_stub).to have_been_requested
        expect(response).to_not be_successful
        expect(response).to have_http_status(401)
        json = JSON.parse(response.body).with_indifferent_access
        expect(json.keys).to contain_exactly("reason")
      end
    end

    context "as user with no role" do
      let(:ministry) { FactoryBot.create(:ministry) }
      it "responds with HTTP 401" do
        ministry.attributes = {name: "Blah"}
        put "/v5/ministries/#{ministry.gr_id}",
          params: ministry.attributes,
          headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

        expect(response).to_not be_successful
        expect(response).to have_http_status(401)
        json = JSON.parse(response.body).with_indifferent_access
        expect(json.keys).to contain_exactly("reason")
      end
    end

    context "as a leader" do
      let(:ministry) { FactoryBot.create(:ministry) }
      let!(:assignment) do
        FactoryBot.create(:assignment, ministry: ministry, person: person,
                                       role: %i[admin leader].sample)
      end

      context "change basic attributes" do
        let(:changes) do
          FactoryBot.build(:ministry).attributes
            .slice(%w[min_code mccs lmi_hide lmi_show])
        end

        it "responds successfully with updated ministry" do
          allow(GrSync::EntityUpdatePush).to receive(:queue_with_root_gr)

          put "/v5/ministries/#{ministry.gr_id}",
            params: changes,
            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(GrSync::EntityUpdatePush).to have_received(:queue_with_root_gr)
            .with(ministry)
          expect(response).to be_successful
          expect(response).to have_http_status(200)
          expect(response.body).to include_json(ministry.attributes.slice(%w[name location_zoom]).merge(changes))
        end
      end

      context "change parent_id to ministry with no role" do
        let(:other) { FactoryBot.create(:ministry) }

        it "responds with HTTP 400" do
          put "/v5/ministries/#{ministry.gr_id}",
            params: {parent_id: other.gr_id},
            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to_not be_successful
          expect(response).to have_http_status(400)
        end
      end

      context "change parent_id to ministry with leader role" do
        let(:other) { FactoryBot.create(:ministry) }
        let!(:other_assignment) do
          FactoryBot.create(:assignment, ministry: other, person: person,
                                         role: %i[admin leader].sample)
        end

        it "responds successfully with updated ministry" do
          put "/v5/ministries/#{ministry.gr_id}",
            params: {parent_id: other.gr_id},
            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status(200)
          expect(response.body).to include_json(ministry_id: ministry.gr_id, parent_id: other.gr_id)
        end
      end
    end

    context "as an inherited leader" do
      let(:parent) { FactoryBot.create(:ministry) }
      let(:ministry) { FactoryBot.create(:ministry, parent: parent) }
      let!(:assignment) do
        FactoryBot.create(:assignment, ministry: parent, person: person,
                                       role: %i[admin leader].sample)
      end

      context "change basic attributes" do
        let(:changes) { FactoryBot.build(:ministry).attributes.slice(%w[min_code mccs lmi_hide lmi_show]) }

        it "responds successfully with updated ministry" do
          put "/v5/ministries/#{ministry.gr_id}",
            params: changes,
            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status(200)
          expect(response.body).to include_json(ministry.attributes.slice(%w[name location_zoom]).merge(changes))
        end
      end

      context "change parent_id to ministry with leader role" do
        let(:other) { FactoryBot.create(:ministry) }
        let!(:other_assignment) do
          FactoryBot.create(:assignment, ministry: other, person: person,
                                         role: %i[admin leader].sample)
        end

        it "responds successfully with updated ministry" do
          put "/v5/ministries/#{ministry.gr_id}",
            params: {parent_id: other.gr_id},
            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status(200)
          expect(response.body).to include_json(ministry_id: ministry.gr_id, parent_id: other.gr_id)
        end
      end
    end
  end
end
