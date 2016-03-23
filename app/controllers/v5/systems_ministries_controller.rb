# frozen_string_literal: true
module V5
  class SystemsMinistriesController < V5::MinistriesController
    include V5::BaseSystemsController

    private

    def ministry_scope
      case params[:action].to_sym
      when :show, :update
        Ministry.find_by(gr_id: params[:id])
      else
        Ministry.all
      end
    end
  end
end
