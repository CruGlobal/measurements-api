class ImportUtil
  class << self
    def find_ministry_id(id)
      ministry = Ministry.find_by(id: id)
      return ministry.id if ministry
      missing_ministry_by_id(id)
      nil
    end

    def ministry_id_by_gr_id(gr_id)
      ministry = Ministry.ministry(gr_id)
      return ministry.id if ministry
      missing_ministry_by_gr_id(gr_id)
      nil
    end

    def person_id_by_gr_id(gr_id)
      person = Person.find_by(gr_id: gr_id)
      return person.id if person
      entity = Person.find_entity(gr_id, entity_type: 'person')
      unless entity
        @missing_person_gr_ids ||= {}
        Rails.logger.info("No person entity found for gr_id: #{gr_id}") unless @missing_person_gr_ids[gr_id]
        @missing_person_gr_ids[gr_id] = true
        return nil
      end
      person = Person.new
      person.from_entity(entity)
      person.save
      person.id
    end

    private

    def missing_ministry_by_id(id)
      @missing_ministry_ids ||= {}
      return if @missing_ministry_ids[id]
      Rails.logger.info("No ministry found for id: #{id}")
      @missing_ministry_ids[id] = true
    end

    def missing_ministry_by_gr_id(gr_id)
      @missing_ministry_gr_ids ||= {}
      return if @missing_ministry_gr_ids[gr_id]
      Rails.logger.info("No ministry found for gr_id: #{gr_id}")
      @missing_ministry_gr_ids[gr_id] = true
    end
  end
end
