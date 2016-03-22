class Area < ActiveRecord::Base
  has_many :ministries

  class << self
    def for_code(area_code)
      found_area = find_by(code: area_code)
      return found_area if found_area.present?
      create_from_gr(area_code)
    end

    private

    def create_from_gr(area_code)
      entity = get_gr_entity(area_code)
      Area.create!(gr_id: entity['id'], code: area_code, name: entity['area_name'],
                   active: entity['is_active'])
    end

    def get_gr_entity(code)
      response = GlobalRegistryClient.new.entities.get(
        entity_type: 'area', 'filters[area_code]' => code)
      response['entities'].first['area']
    end
  end
end
