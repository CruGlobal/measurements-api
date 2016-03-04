module V5
  class TokenController < V5::BaseUserController
    skip_before_action :authenticate_request, only: :index
    skip_around_action :with_current_power, only: :index

    def index
      build_token
      render_error and return unless @new_token.valid?
      render json: @new_token.save, serializer: V5::TokenAndUserSerializer
    end

    def destroy
      CruLib::AccessToken.del(@access_token.token)
      render status: :ok, plain: 'OK'
    end

    protected

    def build_token
      @new_token ||= NewToken.new
      @new_token.attributes = { st: params[:st], redirect_url: v5_token_index_url }
    end

    def render_error
      api_error @new_token.errors.messages[:st].first
    end
  end
end
