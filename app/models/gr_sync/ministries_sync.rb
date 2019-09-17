# frozen_string_literal: true

module GrSync
  class MinistriesSync
    def initialize(gr_client)
      @gr_client ||= gr_client
    end

    def sync_all
      # Fetches all Ministries from GR and either inserts or updates
      all_gr_ministries do |entity|
        ::Ministry.ministry(entity[:id], true)
      end
    end

    private

    def all_gr_ministries
      raise "block required" unless block_given?
      all_active_ministries do |entity|
        yield entity
      end
      all_ministries_missing_active do |entity|
        yield entity
      end
      all_whq_ministries do |entity|
        yield entity
      end
    end

    # Find id, name for all active ministries
    def all_active_ministries
      raise "block required" unless block_given?
      page_helper.find_entities_each(
        entity_type: "ministry",
        levels: 0,
        fields: "name",
        'filters[parent_id:exists]': true,
        'filters[is_active]': true
      ) do |entity|
        yield entity
      end
    end

    # Find id, name for all ministries missing the active property
    def all_ministries_missing_active
      raise "block required" unless block_given?
      page_helper.find_entities_each(
        entity_type: "ministry",
        levels: 0,
        fields: "name",
        'filters[parent_id:exists]': true,
        'filters[is_active:not_exists]': true
      ) do |entity|
        yield entity
      end
    end

    # All WHQ Ministries - this has overlap with previous queries, but includes approx 50 they miss
    def all_whq_ministries
      raise "block required" unless block_given?
      page_helper.find_entities_each(
        entity_type: "ministry",
        levels: 0,
        fields: "name",
        ruleset: "global_ministries"
      ) do |entity|
        yield entity
      end
    end

    def page_helper
      @page_helper ||= PageHelper.new(@gr_client)
    end
  end
end
