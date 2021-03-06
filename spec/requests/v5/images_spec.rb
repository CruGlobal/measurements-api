# frozen_string_literal: true

require "rails_helper"

RSpec.describe "V5::Images", type: :request do
  let(:json) { JSON.parse(response.body).try(:with_indifferent_access) }
  let(:person) { FactoryBot.create(:person) }
  let(:ministry) { FactoryBot.create(:ministry) }

  describe "POST /v5/images" do
    after(:all) do
      FileUtils.rm_rf(Dir["#{Rails.root}/public/uploads"])
    end

    context "author uploads image" do
      let(:story) { FactoryBot.create(:story, created_by: person, ministry: ministry) }
      let(:image) do
        Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "images", "image.jpg"), "image/jpeg")
      end

      it "responds successfully" do
        post "/v5/images?story_id=#{story.id}",
          params: {"image-file" => image},
          headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

        expect(response).to be_successful
        expect(response).to have_http_status :created
        expect(json).to include(:story_id, :image_url)
      end
    end

    context "story with existing image" do
      let(:image) do
        Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "images", "image.jpg"), "image/jpeg")
      end
      let(:other) do
        Rack::Test::UploadedFile.new(File.join(Rails.root, "spec", "support", "images", "image2.jpg"), "image/jpeg")
      end
      let(:story) { FactoryBot.create(:story, created_by: person, ministry: ministry, image: image) }

      it "replaces existing image" do
        post "/v5/images?story_id=#{story.id}",
          params: {"image-file" => other},
          headers: {'HTTP_AUTHORIZATION': "Bearer #{authenticate_person person}"}

        expect(response).to be_successful
        expect(response).to have_http_status :created
        expect(json).to include(:story_id, :image_url)
        expect(json[:image_url]).to end_with "image2.jpg"
      end
    end
  end
end
