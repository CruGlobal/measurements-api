# frozen_string_literal: true
class Area < ApplicationRecord
  has_many :ministries

  class << self
    def for_code(area_code)
      return nil unless area_code.present?
      found_area = find_by(code: area_code)
      return found_area if found_area.present?
      create_from_gr_for_code(area_code)
    end

    def for_gr_id(gr_id)
      return unless gr_id.present?
      found_area = find_by(gr_id: gr_id)
      return found_area if found_area.present?
      create_from_gr_for_id(gr_id)
    end

    private

    def create_from_gr_for_code(area_code)
      entity = gr_entity_for_code(area_code)
      create_from_entity(entity)
    end

    def create_from_gr_for_id(gr_id)
      entity = gr_client.find(gr_id)['entity']['area']
      create_from_entity(entity)
    end

    def gr_entity_for_code(code)
      response = gr_client.get(entity_type: 'area', 'filters[area_code]' => code)
      response['entities'].first['area']
    end

    def gr_client
      GlobalRegistryClient.new.entities
    end

    def create_from_entity(entity)
      Area.create!(gr_id: entity['id'], code: entity['area_code'],
                   name: entity['area_name'], active: entity['is_active'])
    end
  end
end
