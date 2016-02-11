require 'rails_helper'

describe V5::ChurchSerializer do
  describe 'cluster of churchs' do
    let(:resource) do
      @p = FactoryGirl.create(:church, name: 'parent church')
      c = FactoryGirl.create(:church, name: 'churchy kind of name', jf_contrib: true,
                                      target_area_id: SecureRandom.uuid, start_date: '2012-06-08',
                                      parent_id: @p.id)
      [@p, c, FactoryGirl.create(:church, name: 'child church', parent_id: c.id)]
    end
    let(:serializer) { V5::ChurchClusterSerializer.new(resource) }
    let(:serialization) { ActiveModel::Serializer::Adapter.create(serializer) }
    let(:hash) { serialization.as_json }

    it 'has attributes' do
      expect(hash[:latitude]).to_not be_nil
      expect(hash[:longitude]).to_not be_nil
      expect(hash[:jf_contrib]).to be 1
      expect(hash[:cluster_count]).to be 3
      expect(hash[:id]).to_not be_nil
      expect(hash[:gr_id]).to be_nil
      expect(hash[:ministry_id]).to eq @p.target_area_id
      expect(hash[:parents]).to eq []
    end
  end
end
