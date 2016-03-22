# frozen_string_literal: true
module V5
  class PaginatedSerializer < ActiveModel::Serializer
    attributes :meta

    def meta
      {
        total: object.total_entries,
        from: from,
        to: to,
        page: instance_options[:page],
        total_pages: total_pages
      }
    end

    def from
      if instance_options[:page] > total_pages
        0
      else
        from = object.offset + 1
        from > object.total_entries ? 0 : from
      end
    end

    def to
      if instance_options[:page] > total_pages
        0
      else
        to = object.offset + object.length
        to > object.total_entries ? 0 : to
      end
    end

    def total_pages
      @total_pages ||= (object.total_entries / instance_options[:per_page].to_f).ceil
    end
  end
end
