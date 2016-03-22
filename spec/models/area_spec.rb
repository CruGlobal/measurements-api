require 'rails_helper'

describe Area do
  context '.for_code' do
    it 'finds an existing area by code' do
      area = create(:area, code: 'AAOP')
      expect(Area.for_code('AAOP')).to eq area
    end

    it 'queries the global registry and creates a new are if one does not exist' do
      gr_id = SecureRandom.uuid
      url = "#{ENV['GLOBAL_REGISTRY_URL']}/entities?entity_type=area&"\
        "filters[area_code]=EUWE"
      stub_request(:get, url).to_return(body: {
        entities: [{
          area: {
            id: gr_id, area_code: 'EUWE', is_active: true,
            area_name: 'Western Europe'
          }
        }]
      }.to_json)

      area = Area.for_code('EUWE')

      expect(area).to_not be_new_record
      expect(area.gr_id).to eq gr_id
      expect(area.code).to eq 'EUWE'
      expect(area.name).to eq 'Western Europe'
      expect(area).to be_active
    end
  end
end
