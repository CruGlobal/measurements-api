module V5
  class AssignmentsController < V5::BaseController
    include CruLib::AccessTokenProtectedConcern

    def index
      load_assignments
      render_assignments
    end

    def show
      load_assignment
      render_assignment or api_error('Invalid assignment ID')
    end

    def create
      permit_params %i(username key_guid person_id ministry_id team_role)
      build_assignment
      if save_assignment
        render_assignment :created
      else
        render_errors
      end
    end

    def update
      permit_params %i(team_role)
      load_assignment
      build_assignment
      if save_assignment
        render_assignment :ok
      else
        render_errors
      end
    end

    private

    def load_assignments
      @assignments ||= current_user.assignments
    end

    def load_assignment
      @assignment ||= Assignment.find_by(assignment_id: params[:id])
    end

    def build_assignment
      @assignment ||= Assignment::NewUserAssignment.new
      @assignment.attributes = assignment_params
    end

    def save_assignment
      @assignment.save
    end

    def render_assignment(status = nil)
      status ||= :ok
      render json: @assignment, status: status, serializer: V5::AssignmentSerializer if @assignment
    end

    def render_assignments
      render json: @assignments, status: :ok
    end

    def render_errors
      render json: @assignment.errors.messages, status: :bad_request
    end

    def permit_params(params = {})
      @permitted_params = params
    end

    def assignment_params
      @permitted_params ||= {}
      post_params.permit(@permitted_params)
    end
  end
end
