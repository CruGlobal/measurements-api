module V5
  class ApiErrorPresenter < V5::BasePresenter

    def initialize(api_error)
      @api_error = api_error
    end

    def as_json(options={})
      { reason: @api_error.message == 'Bad token' ? 'INVALID_SESSION' : @api_error.message }
    end

    def to_xml(options={}, &block)
      xml = options[:builder] ||= Builder::XmlMarkup.new
      # fill me in...
    end
  end
end
