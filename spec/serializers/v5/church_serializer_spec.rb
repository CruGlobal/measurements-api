require 'rails_helper'

describe V5::ChurchSerializer do
  describe 'single church' do
    let(:resource) do
      @p = FactoryGirl.create(:church, name: 'parent church')
      c = FactoryGirl.create(:church, name: 'churchy kind of name', jf_contrib: true,
                                      target_area_id: SecureRandom.uuid, start_date: '2012-06-08',
                                      parent_id: @p.id)
      FactoryGirl.create(:church, name: 'child church', parent_id: c.id)
      c
    end
    let(:serializer) { V5::ChurchSerializer.new(resource) }
    let(:serialization) { ActiveModel::Serializer::Adapter.create(serializer) }
    let(:hash) { serialization.as_json }

    it 'has attributes' do
      expect(hash[:id]).to_not be_nil
      expect(hash[:name]).to eq resource.name
      expect(hash[:latitude]).to_not be_nil
      expect(hash[:longitude]).to_not be_nil
      expect(hash[:jf_contrib]).to be_a Integer
      expect(hash[:development]).to be_a Integer
      expect(hash[:ministry_id]).to eq resource.target_area_id
      expect(hash[:cluster_count]).to be_a Integer
      expect(hash[:child_count]).to be 1
      expect(hash[:parents]).to eq [@p.id]
      # expect(hash[:contact_email]).to_not be_nil
      # expect(hash[:contact_name]).to_not be_nil
      # expect(hash[:contact_mobile]).to_not be_nil
      expect(hash[:start_date]).to eq '2012-06-08'
      expect(hash[:size]).to eq resource.size
      expect(hash[:security]).to be 2
    end
  end
end
