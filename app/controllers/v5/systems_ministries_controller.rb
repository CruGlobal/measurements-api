# frozen_string_literal: true
module V5
  class SystemsMinistriesController < V5::MinistriesController
    include V5::BaseSystemsController

    private

    def ministry_scope
      case params[:action].to_sym
      when :show
        ministry
      when :update
        # For our purposes a system is a "user" in the sense that we will sync
        # changes it makes to a ministry back to global registry.
        Ministry::UserUpdatedMinistry.new(ministry) if ministry
      else
        Ministry.all
      end
    end

    def ministry
      @ministry ||= Ministry.find_by(gr_id: params[:id])
    end
  end
end
