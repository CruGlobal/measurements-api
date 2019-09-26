# frozen_string_literal: true

module GrSync
  class EntityUpdatePush
    def self.queue_with_root_gr(record)
      WithGrWorker.queue_call_with_root(self, :update_in_gr,
        record.class.name, record.id)
    end

    def initialize(gr_client)
      @gr_client = gr_client
    end

    def update_in_gr(model_name, id)
      record = model_name.constantize.find(id)
      @gr_client.entity.put(record.gr_id, record.to_entity)
    end
  end
end
