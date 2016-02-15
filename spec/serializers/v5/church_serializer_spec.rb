require 'rails_helper'

describe V5::ChurchSerializer do
  describe 'single church' do
    let(:resource) do
      @p = FactoryGirl.create(:church, name: 'parent church')
      c = FactoryGirl.create(:church, name: 'churchy kind of name', jf_contrib: true,
                                      target_area_id: SecureRandom.uuid, start_date: '2012-06-08',
                                      parent_id: @p.id, contact_name: 'doesnt matter',
                                      contact_email: 'what', contact_mobile: 'unvalidated string')
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
      expect(hash[:contact_email]).to_not be_nil
      expect(hash[:contact_name]).to_not be_nil
      expect(hash[:contact_mobile]).to_not be_nil
      expect(hash[:start_date]).to eq '2012-06-08'
      expect(hash[:size]).to eq resource.size
      expect(hash[:security]).to be 2
    end

    it 'points to parent inside cluster' do
      resource.parent_cluster_id = resource.id + 2

      expect(hash[:parents]).to eq [resource.id + 2]
    end

    describe 'when using period' do
      let(:serializer) { V5::ChurchSerializer.new(resource, scope: { period: '2012-08' }) }
      let!(:church_value) do
        resource.church_values.create(period: '2013-01', size: 10,
                                      development: resource[:development] + 1)
      end
      context 'has no past values' do
        it 'returns normal value' do
          expect(hash[:development]).to be resource[:development]
        end
      end
      context 'has past values' do
        before do
          church_value.update(period: '2012-07')
          resource.church_values.create(period: '2012-01', size: 1, development: resource[:development])
          resource.church_values.create(period: '2013-01', size: 1, development: resource[:development])
        end
        it 'returns past value' do
          expect(hash[:development]).to be church_value.development
        end
      end
    end
  end
end
