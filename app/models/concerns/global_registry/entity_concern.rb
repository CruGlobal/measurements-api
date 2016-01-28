module GlobalRegistry
  module EntityConcern
    extend ActiveSupport::Concern

    module ClassMethods
      def find_by(id, params = {})
        response = GlobalRegistry::Entity.find(id, params)
        response['entity'] if response.key?('entity')
      end

      def find_each(params = {})
        fail 'block required' unless block_given?
        find_in_batches(params) do |entities|
          entities.each do |entity|
            next unless entity.key? params[:entity_type]
            yield entity.fetch(params[:entity_type])
          end
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def find_in_batches(params = {})
        fail 'block required' unless block_given?
        params['page'] = 1 unless params.key? 'page'
        params['per_page'] = 50 unless params.key? 'per_page'
        loop do
          response = GlobalRegistry::Entity.get(params)
          yield response['entities'] if response.key? 'entities'
          break if true # response.key?('meta') && (response['meta']['next_page'] == false)
          params['page'] += 1
        end
      end
      # rubocop:enable Metrics/CyclomaticComplexity

    end
  end
end
