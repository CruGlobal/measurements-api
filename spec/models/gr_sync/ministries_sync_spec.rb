# frozen_string_literal: true
require 'spec_helper'

describe GrSync::MinistriesSync, '#sync_all' do
  it 'creates missing ministries from global registry, updates existing ones' do
    request_stubs = [
      stub_ministries_page('is_active', 1, true, [{ id: '1' }, { id: '2' }]),
      stub_ministries_page('is_active', 2, false, [{ id: '3' }]),
      stub_ministries_page('is_active:not_exists', 1, true, [{ id: '4' }]),
      stub_ministries_page('is_active:not_exists', 2, false, [{ id: '5' }]),
      stub_whq_ministries
    ]
    allow(::Ministry).to receive(:ministry)

    GrSync::MinistriesSync.new(GlobalRegistryClient.new).sync_all

    %w(1 2 3 4 5).each do |id|
      expect(::Ministry).to have_received(:ministry).with(id, true).ordered
    end
    request_stubs.each { |stub| expect(stub).to have_been_requested }
  end

  def stub_ministries_page(is_active, page, has_next_page, ministries)
    url = "#{ENV['GLOBAL_REGISTRY_URL']}/entities?"\
      "entity_type=ministry&fields=name&filters%5B#{is_active}%5D=true&"\
      "filters%5Bparent_id:exists%5D=true&levels=0&page=#{page}&per_page=50"
    body = {
      entities: ministries.map { |m| { ministry: m } },
      meta: { page: page, next_page: has_next_page }
    }
    stub_request(:get, url).to_return(body: body.to_json)
  end

  def stub_whq_ministries
    url = "#{ENV['GLOBAL_REGISTRY_URL']}/entities?"\
      'entity_type=ministry&fields=name&levels=0&page=1&per_page=50&ruleset=global_ministries'
    body = {
      entities: [{ ministry: { id: 6 } }],
      meta: { page: 1, next_page: false }
    }
    stub_request(:get, url).to_return(body: body.to_json)
  end
end
