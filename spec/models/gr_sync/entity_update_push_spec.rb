# frozen_string_literal: true

require "rails_helper"

describe GrSync::EntityUpdatePush do
  context ".queue_call_with_root" do
    it "queues a WithGrWorker for the specified record" do
      record = build_stubbed(:ministry, id: 1)
      allow(GrSync::WithGrWorker).to receive(:queue_call_with_root)

      GrSync::EntityUpdatePush.queue_with_root_gr(record)

      expect(GrSync::WithGrWorker).to have_received(:queue_call_with_root)
        .with(GrSync::EntityUpdatePush, :update_in_gr, "Ministry", 1)
    end

    it "works correctly to call update_in_gr when run" do
      record = build_stubbed(:ministry, id: 1)
      entity_update_push = instance_double(GrSync::EntityUpdatePush,
        update_in_gr: nil)
      allow(GrSync::EntityUpdatePush).to receive(:new) { entity_update_push }
      gr_client = double
      allow(GlobalRegistryClient).to receive(:new).with({}) { gr_client }
      clear_uniqueness_locks

      Sidekiq::Testing.inline! do
        GrSync::EntityUpdatePush.queue_with_root_gr(record)
      end

      expect(GrSync::EntityUpdatePush).to have_received(:new).with(gr_client)
      expect(entity_update_push).to have_received(:update_in_gr).with("Ministry", 1)
    end
  end

  context "update_in_gr" do
    it "pushing the entity for the specified model record" do
      entity = {entity: {ministry: {name: "name"}}}
      ministry = build_stubbed(:ministry)
      allow(ministry).to receive(:to_entity).and_return(entity)
      allow(Ministry).to receive(:find).with(ministry.id) { ministry }
      url = "#{ENV["GLOBAL_REGISTRY_URL"]}/entities/#{ministry.gr_id}"
      request_stub = stub_request(:put, url).with(body: entity.to_json)
        .to_return(status: 200, headers: {}, body: "{}")
      gr_client = GlobalRegistryClient.new

      GrSync::EntityUpdatePush.new(gr_client).update_in_gr("Ministry", ministry.id)

      expect(request_stub).to have_been_requested
    end
  end
end
