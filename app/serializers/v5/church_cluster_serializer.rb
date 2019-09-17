# frozen_string_literal: true

module V5
  class ChurchClusterSerializer < ActiveModel::Serializer
    attributes :latitude, :longitude, :jf_contrib, :cluster_count, :id, :gr_id, :ministry_id, :parents

    def latitude
      object.inject(0.0) { |a, e| a + e.latitude }.to_f / object.size
    end

    def longitude
      object.inject(0.0) { |a, e| a + e.longitude }.to_f / object.size
    end

    def jf_contrib
      object.count(&:jf_contrib)
    end

    def cluster_count
      object.count
    end

    def id
      object.first.try(:id)
    end

    def gr_id
      nil
    end

    def ministry_id
      object.first.ministry.gr_id
    end

    def parents
      object.collect(&:parent_id).compact.uniq - object.collect(&:id)
    end
  end
end
