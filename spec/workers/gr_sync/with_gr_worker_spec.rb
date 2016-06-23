# frozen_string_literal: true
require 'rails_helper'

describe GrSync::WithGrWorker do
  module GrSync
    class Test
      def initialize(_gr_client)
      end

      def test(_arg)
      end
    end
  end

  context '.queue_call' do
    it 'injects a global registry client and calls the specified method' do
      gr_params = { 'access_token' => 'zzz' }
      gr_client = instance_double(GrSync::Test)
      allow(GlobalRegistryClient).to receive(:new) { gr_client }
      gr_sync_test = double(test: nil)
      allow(GrSync::Test).to receive(:new) { gr_sync_test }
      clear_uniqueness_locks

      expect do
        GrSync::WithGrWorker.queue_call(gr_params, GrSync::Test, :test, 'arg')
      end.to change(GrSync::WithGrWorker.jobs, :size).by(1)
      expect do
        GrSync::WithGrWorker.drain
      end.to change(GrSync::WithGrWorker.jobs, :size).by(-1)

      expect(GlobalRegistryClient).to have_received(:new).with(gr_params)
      expect(gr_sync_test).to have_received(:test).with('arg')
    end

    it 'errors if class given does not in GrSync:: namespace' do
      expect do
        GrSync::WithGrWorker.new.perform({}, Assignment, :delete_all, [])
      end.to raise_error(/not in GrSync::/)
    end
  end
end
