# frozen_string_literal: true

require "rails_helper"

RSpec.describe "V5::Stories", type: :request do
  let(:json) { JSON.parse(response.body).try(:with_indifferent_access) }
  let(:person) { FactoryBot.create(:person) }
  let(:ministry) { FactoryBot.create(:ministry) }
  let(:training) { FactoryBot.create(:training, ministry: ministry) }
  let(:church) { FactoryBot.create(:church, ministry: ministry) }

  describe "GET /v5/stories" do
    let(:author) { FactoryBot.create(:person) }
    let(:sub_ministry) { FactoryBot.create(:ministry, parent: ministry) }
    let!(:stories) do
      [FactoryBot.create(:story, created_by: author, ministry: ministry, created_at: 4.days.ago, mcc: "slm"),
       FactoryBot.create(:story, created_by: author, ministry: ministry, church: church, created_at: 1.day.ago,
                                 mcc: "gcm"),
       FactoryBot.create(:story, created_by: author, ministry: ministry, training: training, created_at: 3.days.ago,
                                 mcc: "ds"),
       FactoryBot.create(:story, created_by: author, ministry: ministry, training: training, church: church,
                                 created_at: 7.days.ago, mcc: nil),
       FactoryBot.create(:story, created_by: person, ministry: ministry, created_at: 5.days.ago, mcc: "slm"),
       FactoryBot.create(:story, created_by: author, ministry: sub_ministry, created_at: 6.days.ago, mcc: "slm"),
       FactoryBot.create(:story, created_by: author, ministry: sub_ministry, privacy: :team_only,
                                 created_at: 2.days.ago, mcc: "gcm"),
       FactoryBot.create(:story, created_by: person, ministry: sub_ministry, state: :draft, created_at: 8.days.ago,
                                 mcc: "llm"),]
    end

    context "no assignment" do
      it "responds successfully" do
        get "/v5/stories", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(json).to include(:stories, :meta)
        expect(json[:meta]["total"]).to be 6
        expect(json[:stories]).to contain_exactly(
          a_hash_including("story_id" => stories[1].id),
          a_hash_including("story_id" => stories[2].id),
          a_hash_including("story_id" => stories[0].id),
          a_hash_including("story_id" => stories[4].id),
          a_hash_including("story_id" => stories[5].id)
        )
      end

      context "page and per_page" do
        it "responds successfully" do
          get "/v5/stories", params: {page: 2, per_page: 2},
                             headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(json).to include(:stories, :meta)
          expect(json[:meta]["total"]).to be 6
          expect(json[:stories]).to contain_exactly(
            a_hash_including("story_id" => stories[0].id),
            a_hash_including("story_id" => stories[4].id)
          )
        end
      end

      context "filter by mcc" do
        it "responds successfully" do
          get "/v5/stories", params: {mcc: "slm"}, headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(json).to include(:stories, :meta)
          expect(json[:meta]["total"]).to be 3
          expect(json[:stories]).to contain_exactly(
            a_hash_including("story_id" => stories[0].id),
            a_hash_including("story_id" => stories[4].id),
            a_hash_including("story_id" => stories[5].id)
          )
        end
      end

      context "filter by church" do
        it "responds successfully" do
          get "/v5/stories", params: {church_id: church.id},
                             headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(json).to include(:stories, :meta)
          expect(json[:meta]["total"]).to be 2
          expect(json[:stories]).to contain_exactly(
            a_hash_including("story_id" => stories[1].id),
            a_hash_including("story_id" => stories[3].id)
          )
        end
      end

      context "filter by training" do
        it "responds successfully" do
          get "/v5/stories", params: {training_id: training.id},
                             headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(json).to include(:stories, :meta)
          expect(json[:meta]["total"]).to be 2
          expect(json[:stories]).to contain_exactly(
            a_hash_including("story_id" => stories[2].id),
            a_hash_including("story_id" => stories[3].id)
          )
        end
      end
    end

    context "as an author" do
      context "filter by self_only" do
        it "responds successfully" do
          get "/v5/stories", params: {self_only: "true"},
                             headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(json).to include(:stories, :meta)
          expect(json[:meta]["total"]).to be 2
          expect(json[:stories]).to contain_exactly(
            a_hash_including("story_id" => stories[4].id),
            a_hash_including("story_id" => stories[7].id)
          )
        end
      end
    end
  end

  describe "GET /v5/stories/:id" do
    context "unknown story" do
      it "responds with HTTP 404" do
        get "/v5/stories/0", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

        expect(response).to_not be_successful
        expect(response).to have_http_status :not_found
      end
    end

    context "published state" do
      context "public privacy" do
        let(:story) do
          FactoryBot.create(:story, created_by: person, ministry: ministry, privacy: :everyone, state: :published)
        end

        it "responds successfully with the story" do
          get "/v5/stories/#{story.id}", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

          expect(response).to be_successful
          expect(response).to have_http_status :ok
          expect(json[:story_id]).to eq story.id
          expect(json[:created_by]).to be_uuid.and(eq person.gr_id)
          expect(json[:ministry_id]).to be_uuid.and(eq ministry.gr_id)
        end
      end

      context "team_only privacy" do
        let(:story) do
          FactoryBot.create(:story, created_by: person, ministry: ministry, privacy: :team_only, state: :published)
        end

        context "no assignment" do
          it "responds with HTTP 404" do
            get "/v5/stories/#{story.id}", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

            expect(response).to_not be_successful
            expect(response).to have_http_status :not_found
          end
        end

        context "as a member" do
          let(:member) { FactoryBot.create(:person) }
          let!(:assignment) { FactoryBot.create(:assignment, person: member, ministry: ministry, role: :member) }
          it "responds successfully with the story" do
            get "/v5/stories/#{story.id}", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person member}"}

            expect(response).to be_successful
            expect(response).to have_http_status :ok
            expect(json[:story_id]).to eq story.id
            expect(json[:created_by]).to be_uuid.and(eq person.gr_id)
            expect(json[:ministry_id]).to be_uuid.and(eq ministry.gr_id)
          end
        end
      end
    end

    context "draft state" do
      let(:author) { FactoryBot.create(:person) }

      context "public privacy" do
        let(:story) do
          FactoryBot.create(:story, created_by: author, ministry: ministry, privacy: :everyone, state: :draft)
        end

        it "responds with HTTP 404" do
          get "/v5/stories/#{story.id}", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}

          expect(response).to_not be_successful
          expect(response).to have_http_status :not_found
        end
      end

      context "team_only privacy" do
        let(:story) do
          FactoryBot.create(:story, created_by: author, ministry: ministry, privacy: :team_only, state: :draft)
        end

        context "as a member" do
          let!(:assignment) { FactoryBot.create(:assignment, person: person, ministry: ministry, role: :member) }

          it "responds with HTTP 404" do
            get "/v5/stories/#{story.id}", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

            expect(response).to_not be_successful
            expect(response).to have_http_status :not_found
          end
        end

        context "as a leader" do
          let!(:assignment) { FactoryBot.create(:assignment, person: person, ministry: ministry, role: :leader) }

          it "responds successfully with the story" do
            get "/v5/stories/#{story.id}", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

            expect(response).to be_successful
            expect(response).to have_http_status :ok
            expect(json[:story_id]).to eq story.id
            expect(json[:created_by]).to be_uuid.and(eq author.gr_id)
            expect(json[:ministry_id]).to be_uuid.and(eq ministry.gr_id)
          end
        end

        context "as story author" do
          it "responds successfully with the story" do
            get "/v5/stories/#{story.id}", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person author}"}

            expect(response).to be_successful
            expect(response).to have_http_status :ok
            expect(json[:story_id]).to eq story.id
            expect(json[:created_by]).to be_uuid.and(eq author.gr_id)
            expect(json[:ministry_id]).to be_uuid.and(eq ministry.gr_id)
          end
        end
      end
    end
  end

  describe "POST /v5/stories" do
    let(:story_attributes) do
      {title: "A Title", content: "This is my story!", privacy: "team_only", state: "draft",
       image_url: "http://example.com/image.png", ministry_id: ministry.gr_id,
       mcc: "gcm", church_id: church.id, training_id: training.id, language: "en",
       location: {latitude: 12.3456789, longitude: -12.3456789},}
    end

    context "without an assignment" do
      it "responds with HTTP 400" do
        post "/v5/stories", params: story_attributes,
                            headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

        expect(response).to_not be_successful
        expect(response).to have_http_status :bad_request
      end
    end

    context "with an assignment" do
      let!(:assignment) { FactoryBot.create(:assignment, person: person, ministry: ministry, role: :member) }
      context "draft state" do
        it "responds successfully with new story" do
          expect {
            post "/v5/stories", params: story_attributes,
                                headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

            expect(response).to be_successful
            expect(response).to have_http_status :created
          }.to change { Story.count }.by(1).and(change { Audit.count }.by(0))
          expect(Story.last.created_by_id).to eq person.id
        end
      end

      context "published state" do
        it "responds successfully with new story" do
          expect {
            post "/v5/stories", params: story_attributes.merge(state: "published"),
                                headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

            expect(response).to be_successful
            expect(response).to have_http_status :created
          }.to change { Story.count }.by(1).and(change { Audit.count }.by(1))
          expect(Story.last.created_by_id).to eq person.id
        end
      end
    end

    context "inherited assignment" do
      let(:sub_ministry) { FactoryBot.create(:ministry, parent: ministry) }
      let!(:assignment) { FactoryBot.create(:assignment, person: person, ministry: ministry, role: :admin) }
      it "responds successfully with new story" do
        expect {
          post "/v5/stories", params: story_attributes.merge(ministry_id: sub_ministry.gr_id),
                              headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

          expect(response).to be_successful
          expect(response).to have_http_status :created
        }.to change { Story.count }.by(1).and(change { Audit.count }.by(0))
        expect(Story.last.created_by_id).to eq person.id
      end
    end
  end

  describe "PUT /v5/stories/:id" do
    let(:author) { FactoryBot.create(:person) }
    let(:story) do
      FactoryBot.create(:story, created_by: author, ministry: ministry, privacy: :team_only, state: :draft)
    end
    let(:attributes) do
      {title: "A Title", content: "This is my story!", privacy: "public", state: "published",
       image_url: "http://example.com/image.png", mcc: "slm", language: "fr",}
    end

    context "as leader" do
      let!(:assignment) { FactoryBot.create(:assignment, person: person, ministry: ministry, role: :leader) }

      it "responds successfully with updated story" do
        put "/v5/stories/#{story.id}", params: attributes,
                                       headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(json[:title]).to eq attributes[:title]
        expect(json[:content]).to eq attributes[:content]
        expect(json[:image_url]).to eq attributes[:image_url]
        expect(json[:mcc]).to eq attributes[:mcc]
        expect(json[:language]).to eq attributes[:language]
        expect(json[:privacy]).to eq attributes[:privacy]
        expect(json[:state]).to eq attributes[:state]
      end
    end

    context "as member" do
      let!(:assignment) { FactoryBot.create(:assignment, person: person, ministry: ministry, role: :member) }

      it "responds with HTTP 400" do
        put "/v5/stories/#{story.id}", params: attributes,
                                       headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

        expect(response).to_not be_successful
        expect(response).to have_http_status :bad_request
      end
    end

    context "as story author" do
      it "responds successfully with updated story" do
        put "/v5/stories/#{story.id}", params: attributes,
                                       headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person author}"}

        expect(response).to be_successful
        expect(response).to have_http_status :ok
        expect(json[:title]).to eq attributes[:title]
        expect(json[:content]).to eq attributes[:content]
        expect(json[:image_url]).to eq attributes[:image_url]
        expect(json[:mcc]).to eq attributes[:mcc]
        expect(json[:language]).to eq attributes[:language]
        expect(json[:privacy]).to eq attributes[:privacy]
        expect(json[:state]).to eq attributes[:state]
      end
    end
  end
end
