# frozen_string_literal: true

module V5
  class ChurchSerializer < ActiveModel::Serializer
    attributes :name, :latitude, :longitude, :jf_contrib, :cluster_count, :id, :gr_id, :development,
      :ministry_id, :contact_email, :contact_name, :contact_mobile, :start_date, :size,
      :parents, :security, :created_by, :created_by_email, :child_count

    def jf_contrib
      object.jf_contrib ? 1 : 0
    end

    def cluster_count
      1
    end

    def child_count
      object.children_count
    end

    def development # rubocop:disable Metrics/AbcSize
      if scope && scope[:period] && scope[:period] != Time.zone.today.strftime("%Y-%m")
        Church.developments[object.value_at(scope[:period], scope[:values])[:development]]
      else
        Church.developments[object[:development]]
      end
    end

    def security
      s = Church.securities[object[:security]]
      s == 0 ? 1 : s
    end

    def parents
      p_id = object.parent_cluster_id || object.parent.try(:id)
      p_id ? [p_id] : []
    end

    def ministry_id
      object.ministry.try(:gr_id)
    end

    def created_by
      object.created_by.try(:gr_id)
    end
  end
end
