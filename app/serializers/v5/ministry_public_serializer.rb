# frozen_string_literal: true
module V5
  class MinistryPublicSerializer < ActiveModel::Serializer
    # Only renders "public" ministry attributes
    attributes :ministry_id, :name

    def ministry_id
      object.gr_id
    end
  end
end
