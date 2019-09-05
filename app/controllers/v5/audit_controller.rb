# frozen_string_literal: true

module V5
  class AuditController < V5::BaseUserController
    DEFAULT_PAGE = 1
    DEFAULT_PER_PAGE = 10

    power :audits, as: :audit_scope

    def index
      if params[:per_page]
        audits = load_audits
        render json: audits,
               serializer: V5::AuditArraySerializer,
               page: page,
               per_page: per_page
      else
        render json: load_audits,
               each_serializer: V5::AuditSerializer
      end
    end

    private

    def load_audits
      audits = audit_scope.order(created_at: :desc)
      if params[:per_page]
        audits.paginate(page: page, per_page: per_page)
      else
        audits.limit(params[:number_of_entries] || DEFAULT_PER_PAGE)
      end
    end

    def page
      page_int = params[:page].try(:to_i) || DEFAULT_PAGE
      page_int.to_i > 0 ? page_int : DEFAULT_PAGE
    end

    def per_page
      per_page_int = params[:per_page].try(:to_i) || DEFAULT_PER_PAGE
      per_page_int.to_i > 0 ? per_page_int : DEFAULT_PER_PAGE
    end
  end
end
