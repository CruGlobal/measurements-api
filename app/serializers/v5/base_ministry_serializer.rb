# frozen_string_literal: true

module V5
  class BaseMinistrySerializer < ActiveModel::Serializer
    MINISTRY_ATTRIBUTES = %i[name
                             min_code
                             ministry_scope
                             location
                             location_zoom
                             lmi_show
                             lmi_hide
                             mccs
                             default_mcc
                             hide_reports_tab].freeze

    attributes :ministry_id, :parent_id, :content_locales
    attributes(*self::MINISTRY_ATTRIBUTES)

    def attributes(requested_attrs = nil, reload = false)
      # Remove nil values
      super.reject { |_k, v| v.nil? }
    end

    def ministry_id
      object.gr_id
    end

    def parent_id
      object.parent.try(:gr_id)
    end

    def content_locales
      # Array of locales
      object.user_content_locales.pluck(:locale).try(:uniq)
    end
  end
end
