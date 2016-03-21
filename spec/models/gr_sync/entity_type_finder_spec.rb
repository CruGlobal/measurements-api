require 'rails_helper'

describe GrSync::EntityTypeFinder do
  context '.entity_type_ids' do
    it 'retrieves the entity type ids filtered by name' do
      url = "#{ENV['GLOBAL_REGISTRY_URL']}/entity_types?"\
        'filters[name][]=ministry&filters[name][]=person'
      stub_request(:get, url)
        .with(query: 'filters[name][]=ministry&filters[name][]=person')
        .to_return(body: { entity_types: [{ id: '1f' }, { id: '2f' }] }.to_json)

      type_ids = GrSync::EntityTypeFinder.entity_type_ids(%w(ministry person))

      expect(type_ids).to eq(%w(1f 2f))
    end
  end
end
