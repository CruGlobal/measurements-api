require 'rails_helper'

describe V5::StorySerializer do
  describe 'a story' do
    let(:ministry) { FactoryGirl.create(:ministry) }
    let(:person) { FactoryGirl.create(:person) }
    let(:story) do
      FactoryGirl.create(:story, created_by: person, ministry: ministry, privacy: :everyone, state: :published)
    end
    let(:serializer) { V5::StorySerializer.new(story) }
    let(:serialization) { ActiveModel::Serializer::Adapter.create(serializer) }
    let(:json) { serialization.as_json }

    it 'has attributes' do
      story.reload
      expect(json[:story_id]).to_not be_nil
      expect(json[:created_by]).to be_uuid.and(eq person.gr_id)
      expect(json[:ministry_id]).to be_uuid.and(eq ministry.gr_id)
      expect(json[:title]).to eq story.title
      expect(json[:content]).to eq story.content
      expect(json[:mcc]).to eq story.mcc
      expect(json[:location]).to be_a Hash
      expect(json[:location]).to include(latitude: story.latitude, longitude: story.longitude)
      expect(json[:privacy]).to eq 'public'
      expect(json[:state]).to eq 'published'
      expect(json[:created_at]).to eq story.created_at.strftime('%Y-%m-%d')
      expect(json[:updated_at]).to eq story.updated_at.strftime('%Y-%m-%d')
    end

    context 'with related training' do
      let(:training) { FactoryGirl.create(:training, ministry: ministry) }
      it 'has related training_id' do
        story.training = training
        expect(json[:training_id]).to be_an(Integer).and(eq training.id)
      end
    end

    context 'with related training' do
      let(:church) { FactoryGirl.create(:church, ministry: ministry) }
      it 'has related training_id' do
        story.church = church
        expect(json[:church_id]).to be_an(Integer).and(eq church.id)
      end
    end

    context 'with image_url and video_url' do
      let!(:urls) do
        story.image_url = 'https://example.com/story.jpg'
        story.video_url = 'https://example.com/video.mp4'
      end
      it 'includes image/video urls' do
        expect(json[:image_url]).to eq story.image_url
        expect(json[:video_url]).to eq story.video_url
      end

      context 'with uploaded image' do
        after do
          FileUtils.rm_rf(Dir["#{Rails.root}/public/uploads"])
        end
        let!(:image) do
          story.image = Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec', 'support', 'images', 'image.jpg'))
        end
        it 'has uploaded image url' do
          expect(json[:image_url]).to eq story.image.url
        end
      end
    end
  end
end
