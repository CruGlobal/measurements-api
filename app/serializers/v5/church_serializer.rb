module V5
  class ChurchSerializer < ActiveModel::Serializer
    attributes :name, :latitude, :longitude, :jf_contrib, :cluster_count, :id, :gr_id, :development,
               :ministry_id, :contact_email, :contact_name, :contact_mobile, :start_date, :size,
               :parents, :security, :created_by, :created_by_email, :child_count

    def jf_contrib
      object.jf_contrib ? 1 : 0
    end

    def cluster_count
      0
    end

    def child_count
      object.children.count
    end

    def development
      if scope && scope[:period]
        object.value_at(scope[:period])[:development]
      else
        object[:development]
      end
    end

    def security
      object[:security]
    end

    def parents
      [object.parent_cluster_id || object.parent.try(:id)]
    end

    def ministry_id
      object.ministry.gr_id
    end
  end
end
