# frozen_string_literal: true

require "rails_helper"

RSpec.describe "V5::Audits", type: :request do
  let(:ministry) { FactoryBot.create(:ministry) }
  let(:user) { FactoryBot.create(:person) }

  describe "GET /v5/audit" do
    let(:json) { JSON.parse(response.body) }

    before do
      3.times do |i|
        # create audits in reverse order so we can test sorting
        FactoryBot.create(:audit, person: user, ministry: ministry, created_at: (2 - i).months.ago)
      end
    end

    context "as admin" do
      let!(:assignment) { FactoryBot.create(:assignment, person: user, ministry: ministry, role: :admin) }
      it "responds with audits" do
        get "/v5/audit", params: {ministry_id: ministry.gr_id, number_of_entries: 2},
                         headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"}

        expect(response).to be_successful
        expect(json.count).to be 2
        expect(json.first["timestamp"]).to eq Time.zone.now.strftime("%Y-%m-%d")
        expect(json.last["timestamp"]).to eq 1.month.ago.strftime("%Y-%m-%d")
      end
      it "responds with paged audits" do
        get "/v5/audit", params: {ministry_id: ministry.gr_id, per_page: 2, page: 1},
                         headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"}

        expect(response).to be_successful
        expect(json["entries"].count).to be 2
        expect(json["entries"].first["timestamp"]).to eq Time.zone.now.strftime("%Y-%m-%d")
        expect(json["entries"].last["timestamp"]).to eq 1.month.ago.strftime("%Y-%m-%d")
        expect(json["meta"]["total_pages"]).to be 2
        expect(json["meta"]["total"]).to be 3
      end
    end

    context "as self-assigned" do
      let!(:assignment) { FactoryBot.create(:assignment, person: user, ministry: ministry, role: :self_assigned) }
      it "fails to fetch audits" do
        get "/v5/audit", params: {ministry_id: ministry.gr_id},
                         headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person(user)}"}

        expect(response).to_not be_successful
      end
    end
  end
end
