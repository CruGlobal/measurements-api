module GrSync
  class PageHelper
    def initialize(gr_client)
      @gr_client = gr_client
    end

    # Find Entities (internally uses find_entities_in_batches)
    def find_entities_each(params = {})
      raise 'block required' unless block_given?
      find_entities_in_batches(params) do |entities|
        entities.each do |entity|
          next unless entity.key?(params[:entity_type])
          yield entity.fetch(params[:entity_type]).with_indifferent_access
        end
      end
    end

    # Find Entities in paged batches
    def find_entities_in_batches(params = {})
      raise 'block required' unless block_given?
      params['page'] = 1 unless params.key? 'page'
      params['per_page'] = 50 unless params.key? 'per_page'
      loop do
        response = @gr_client.entities.get(params)
        yield response['entities'] if response.key? 'entities'
        break if response.key?('meta') && (response['meta']['next_page'] == false)
        params['page'] += 1
      end
    end
  end
end
