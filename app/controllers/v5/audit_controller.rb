module V5
  class AuditController < V5::BaseUserController
    power :audits, as: :audit_scope

    def index
      render json: load_audits,
             each_serializer: V5::AuditSerializer
    end

    private

    def load_audits
      audit_scope.limit(params[:number_of_entries] || 10).order(created_at: :desc)
    end
  end
end
