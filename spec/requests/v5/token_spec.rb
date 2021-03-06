# frozen_string_literal: true

require "rails_helper"

RSpec.describe "V5::Tokens", type: :request do
  describe "GET /v5/tokens" do
    context "with valid st" do
      before :each do
        validate_ticket_request(user)
      end

      context "as unknown user" do
        let(:user) do
          FactoryBot.build(:person)
        end

        before do
          gr_person_request_by_guid(user)
        end

        it "responds with session_ticket" do
          get "/v5/token", params: {st: "asdf"}
          json = JSON.parse(response.body)

          expect(response).to be_successful
          expect(json["session_ticket"]).to_not be_nil
        end
      end

      context "as existing user" do
        let(:user) do
          FactoryBot.create(:person)
        end

        it "responds with session_ticket" do
          get "/v5/token", params: {st: "asdf"}
          json = JSON.parse(response.body)

          expect(response).to be_successful
          expect(json["session_ticket"]).to_not be_nil
        end

        it "includes default_map_views" do
          user.user_map_views.create(ministry: create(:ministry), zoom: 11)

          get "/v5/token", params: {st: "asdf"}
          json = JSON.parse(response.body)

          expect(json["user_preferences"]["default_map_views"]).to_not be_nil
        end
      end
    end

    context "with no st" do
      it "renders error" do
        get "/v5/token"
        expect(response).to_not be_successful

        json = JSON.parse(response.body)
        expect(json["reason"]).to eq "You must pass in a service ticket ('st' parameter)"
      end
    end

    context "with no st" do
      it "renders error" do
        st = SecureRandom.hex
        stub_request(:get, "#{ENV["CAS_BASE_URL"]}/proxyValidate?service=http://www.example.com/v5/token&ticket=#{st}")
          .to_return(body: invalid_ticket_response)

        get "/v5/token", params: {st: st}
        expect(response).to_not be_successful

        json = JSON.parse(response.body)
        expect(json["reason"]).to eq "denied"
      end
    end
  end

  describe "DELETE /v5/tokens" do
    it "removes token from redis" do
      expect_any_instance_of(Redis).to receive(:del)
      delete "/v5/token", headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person}"}
    end
  end
end
