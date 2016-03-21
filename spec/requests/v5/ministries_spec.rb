require 'rails_helper'

RSpec.describe 'V5::Ministries', type: :request do
  describe 'GET /v5/ministries' do
    let!(:ministries) do
      ministries = []
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.id)
      ministries << FactoryGirl.create(:ministry, parent_id: ministries.sample.id)
      ministries
    end

    it 'responds with all ministries' do
      get '/v5/ministries', nil, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"
      expect(response).to be_success
      json = JSON.parse(response.body)
      expect(json.length).to be ministries.length
    end

    context 'with refresh=true' do
      it 'responds with HTTP 202 Accepted' do
        clear_uniqueness_locks
        expect do
          get '/v5/ministries', { refresh: true }, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"
          expect(response).to be_success
          expect(response).to have_http_status(202)
        end.to change(GrSync::WithGrWorker.jobs, :size).by(1)
      end
    end
  end

  describe 'GET /v5/ministries/:id' do
    let(:person) { FactoryGirl.create(:person) }
    let(:ministry) { FactoryGirl.create(:ministry) }

    context 'without an assignment' do
      it 'responds with HTTP 401' do
        get "/v5/ministries/#{ministry.gr_id}", nil, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"
        expect(response).to have_http_status(401)
        json = JSON.parse(response.body)
        expect(json.keys).to contain_exactly('reason')
      end
    end

    context 'with an admin or leader assignment' do
      let!(:assignment) do
        FactoryGirl.create(:assignment, person_id: person.id, ministry_id: ministry.id,
                                        role: %i(admin leader).sample)
      end

      it 'responds with the ministry details' do
        get "/v5/ministries/#{ministry.gr_id}", nil,
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

        expect(response).to be_success
        expect(response).to have_http_status(200)
        expect(response.body).to include_json(ministry_id: ministry.gr_id, min_code: ministry.min_code)
      end
    end

    context 'with an inherited admin or leader assignment' do
      let(:sub_ministry) { FactoryGirl.create(:ministry, parent: ministry) }
      let!(:assignment) do
        FactoryGirl.create(:assignment, person: person, ministry: ministry,
                                        role: %i(admin leader).sample)
      end

      it 'responds with the ministry details' do
        get "/v5/ministries/#{sub_ministry.gr_id}", nil,
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

        expect(response).to be_success
        expect(response).to have_http_status(200)
        expect(response.body).to include_json(ministry_id: sub_ministry.gr_id, min_code: sub_ministry.min_code)
      end
    end

    context 'with a non admin/leader assignment' do
      let!(:assignment) do
        FactoryGirl.create(:assignment,
                           person_id: person.id,
                           ministry_id: ministry.id,
                           role: %i(blocked former_member self_assigned member).sample)
      end

      it 'responds with HTTP 401' do
        get "/v5/ministries/#{ministry.gr_id}", nil,
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"
        expect(response).to have_http_status(401)
        json = JSON.parse(response.body)
        expect(json.keys).to contain_exactly('reason')
      end
    end
  end

  describe 'POST /v5/ministries' do
    context 'create a ministry' do
      let(:person) { FactoryGirl.create(:person) }
      context 'with required attributes' do
        let(:ministry) { FactoryGirl.build(:ministry) }
        let!(:gr_request_stub) { gr_create_ministry_request(ministry) }
        it 'responds successfully with the new ministry' do
          expect do
            post '/v5/ministries', ministry.attributes, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

            expect(response).to be_success
            expect(response).to have_http_status(201)
            expect(gr_request_stub).to have_been_requested
            json = JSON.parse(response.body).with_indifferent_access
            expect(json[:ministry_id]).to be_uuid.and(eq ministry.gr_id)

            assignment = person.assignment_for_ministry(json[:ministry_id])
            expect(assignment).to_not be_nil
            expect(assignment.leader_role?).to eq true
          end.to change { Ministry.count }.by(1)
        end
      end

      context 'missing required attributes' do
        let(:ministry) { { name: nil, lmi_show: true, mccs: nil, ministry_scope: 'Blah', hello: 123 } }
        it 'responds with HTTP 400' do
          post '/v5/ministries', ministry, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

          expect(response).to_not be_success
          expect(response).to have_http_status(400)
          json = JSON.parse(response.body).with_indifferent_access
          expect(json.keys).to contain_exactly('name', 'min_code')
        end
      end
    end

    context 'create sub-ministry' do
      let(:person) { FactoryGirl.create(:person) }
      let(:parent) { FactoryGirl.create(:ministry) }
      let(:ministry) { FactoryGirl.build(:ministry, parent: parent) }
      let(:attributes) { ministry.attributes.merge parent_id: parent.gr_id }

      context 'as leader of parent ministry' do
        let!(:gr_request_stub) { gr_create_ministry_request(ministry) }
        let!(:assignment) do
          FactoryGirl.create(:assignment, ministry: parent, person: person,
                                          role: %i(admin leader).sample)
        end

        it 'responds successfully with new ministry' do
          expect do
            post '/v5/ministries', attributes, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

            expect(response).to be_success
            expect(response).to have_http_status(201)
            expect(gr_request_stub).to have_been_requested
            json = JSON.parse(response.body).with_indifferent_access
            expect(json[:ministry_id]).to be_uuid.and(eq ministry.gr_id)
            expect(json[:parent_id]).to be_uuid.and(eq parent.gr_id)

            sub_assignment = person.assignment_for_ministry(json[:ministry_id])
            expect(sub_assignment).to_not be_nil
            expect(sub_assignment.leader_role?).to eq true
          end.to change { Ministry.count }.by(1)
        end
      end

      context 'as user with no role on parent ministry' do
        it 'responds with HTTP 400' do
          post '/v5/ministries', attributes, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

          expect(response).to_not be_success
          expect(response).to have_http_status(400)
          json = JSON.parse(response.body).with_indifferent_access
          expect(json.keys).to contain_exactly('parent_id')
        end
      end
    end
  end

  describe 'PUT /v5/ministries/:id' do
    let(:person) { FactoryGirl.create(:person) }
    context 'unknown ministry' do
      let(:ministry) { FactoryGirl.build(:ministry) }
      let!(:gr_request_stub) { gr_get_invalid_ministry_request(ministry) }

      it 'responds with HTTP 401' do
        put "/v5/ministries/#{ministry.gr_id}", ministry.attributes,
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

        expect(gr_request_stub).to have_been_requested
        expect(response).to_not be_success
        expect(response).to have_http_status(401)
        json = JSON.parse(response.body).with_indifferent_access
        expect(json.keys).to contain_exactly('reason')
      end
    end

    context 'as user with no role' do
      let(:ministry) { FactoryGirl.create(:ministry) }
      it 'responds with HTTP 401' do
        ministry.attributes = { name: 'Blah' }
        put "/v5/ministries/#{ministry.gr_id}", ministry.attributes,
            'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

        expect(response).to_not be_success
        expect(response).to have_http_status(401)
        json = JSON.parse(response.body).with_indifferent_access
        expect(json.keys).to contain_exactly('reason')
      end
    end

    context 'as a leader' do
      let(:ministry) { FactoryGirl.create(:ministry) }
      let!(:assignment) do
        FactoryGirl.create(:assignment, ministry: ministry, person: person,
                                        role: %i(admin leader).sample)
      end

      context 'change basic attributes' do
        let(:changes) do
          FactoryGirl.build(:ministry).attributes
                     .slice(%w(min_code mccs lmi_hide lmi_show))
        end

        it 'responds successfully with updated ministry' do
          put "/v5/ministries/#{ministry.gr_id}", changes, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

          expect(response).to be_success
          expect(response).to have_http_status(200)
          expect(response.body).to include_json(ministry.attributes.slice(%w(name location_zoom)).merge(changes))
        end
      end

      context 'change parent_id to ministry with no role' do
        let(:other) { FactoryGirl.create(:ministry) }

        it 'responds with HTTP 400' do
          put "/v5/ministries/#{ministry.gr_id}", { parent_id: other.gr_id },
              'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

          expect(response).to_not be_success
          expect(response).to have_http_status(400)
        end
      end

      context 'change parent_id to ministry with leader role' do
        let(:other) { FactoryGirl.create(:ministry) }
        let!(:other_assignment) do
          FactoryGirl.create(:assignment, ministry: other, person: person,
                                          role: %i(admin leader).sample)
        end

        it 'responds successfully with updated ministry' do
          put "/v5/ministries/#{ministry.gr_id}", { parent_id: other.gr_id },
              'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

          expect(response).to be_success
          expect(response).to have_http_status(200)
          expect(response.body).to include_json(ministry_id: ministry.gr_id, parent_id: other.gr_id)
        end
      end
    end

    context 'as an inherited leader' do
      let(:parent) { FactoryGirl.create(:ministry) }
      let(:ministry) { FactoryGirl.create(:ministry, parent: parent) }
      let!(:assignment) do
        FactoryGirl.create(:assignment, ministry: parent, person: person,
                                        role: %i(admin leader).sample)
      end

      context 'change basic attributes' do
        let(:changes) { FactoryGirl.build(:ministry).attributes.slice(%w(min_code mccs lmi_hide lmi_show)) }

        it 'responds successfully with updated ministry' do
          put "/v5/ministries/#{ministry.gr_id}", changes, 'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

          expect(response).to be_success
          expect(response).to have_http_status(200)
          expect(response.body).to include_json(ministry.attributes.slice(%w(name location_zoom)).merge(changes))
        end
      end

      context 'change parent_id to ministry with leader role' do
        let(:other) { FactoryGirl.create(:ministry) }
        let!(:other_assignment) do
          FactoryGirl.create(:assignment, ministry: other, person: person,
                                          role: %i(admin leader).sample)
        end

        it 'responds successfully with updated ministry' do
          put "/v5/ministries/#{ministry.gr_id}", { parent_id: other.gr_id },
              'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"

          expect(response).to be_success
          expect(response).to have_http_status(200)
          expect(response.body).to include_json(ministry_id: ministry.gr_id, parent_id: other.gr_id)
        end
      end
    end
  end
end
