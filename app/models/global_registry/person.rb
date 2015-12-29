module GlobalRegistry
  class Person
    include ActiveModel::Model

    attr_accessor :id, :first_name, :last_name, :key_guid, :key_username

    class << self
      def find_by_key_guid(guid)
        results = GlobalRegistry::Entity.get(
          entity_type: 'person',
          fields: 'first_name,last_name,key_username,authentication.key_guid',
          'filters[authentication][key_guid]': guid
        )['entities']
        return nil unless results[0] && results[0]['person']
        person = GlobalRegistry::Person.new(results[0]['person'])
        person.key_guid = guid
        person
      rescue RestClient::Exception => e
        raise e.response.to_str
      end
    end
  end
end
