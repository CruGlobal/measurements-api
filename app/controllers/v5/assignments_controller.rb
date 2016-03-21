module V5
  class AssignmentsController < V5::BaseUserController
    power :assignments, map: {
      [:show] => :showable_assignments,
      [:update] => :updateable_assignments
    }, as: :assignment_scope

    def index
      load_assignments
      render_assignments
    end

    def show
      load_assignment
      render_assignment or api_error('Invalid assignment id')
    end

    def create
      permit_params %i(username key_guid person_id ministry_id team_role)
      if build_assignment
        render_assignment :created
      else
        render_errors
      end
    end

    def update
      permit_params %i(team_role)
      load_assignment or api_error('Invalid assignment id') && return
      if build_assignment
        render_assignment :ok
      else
        render_errors
      end
    end

    private

    def request_power
      ministry_id = case params[:action].to_sym
                    when :update, :show
                      Assignment.find_by(gr_id: params[:id]).try(:ministry).try(:gr_id)
                    else
                      params[:ministry_id]
                    end
      Power.new(current_user, ministry_id)
    end

    def load_assignments
      @assignments ||= assignment_scope
    end

    def load_assignment
      @assignment ||= find_and_decorate_assignment
    end

    def find_and_decorate_assignment
      found_assignment = assignment_scope.find_by(gr_id: params[:id])
      return nil unless found_assignment.present?
      ::Assignment::UserUpdatedAssignment.new(found_assignment)
    end

    def build_assignment
      @assignment ||= ::Assignment::UserCreatedAssignment.new
      @assignment.attributes = assignment_params
      @assignment.save
    end

    def render_assignment(status = nil)
      status ||= :ok
      render json: @assignment, status: status, serializer: V5::AssignmentSerializer if @assignment
    end

    def render_assignments
      render json: @assignments, status: :ok, each_serializer: V5::AssignmentSerializer
    end

    def render_errors
      render json: @assignment.errors.messages, status: :bad_request
    end

    def permit_params(params = {})
      @permitted_params = params
    end

    def assignment_params
      @permitted_params ||= {}
      attributes = post_params.permit(@permitted_params)
      # Rename and delete uuid params
      { person_id: :person_gr_id, ministry_id: :ministry_gr_id }.each do |k, v|
        attributes[v] = attributes[k] if attributes.key?(k) && Uuid.uuid?(attributes[k])
        attributes.delete(k)
      end
      attributes
    end

    def render_consul_powerless(exception)
      message = case params[:action].to_sym
                when :show
                  '\'ministry_id\' missing or invalid'
                else
                  exception.message
                end
      api_error(message, status: :unauthorized)
    end
  end
end
