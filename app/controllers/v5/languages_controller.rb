# frozen_string_literal: true
module V5
  class LanguagesController < BaseController
    def index
      load_languages
      render_languages
    end

    private

    def load_languages
      @languages ||= File.read("#{Rails.root}/public/languages.json")
    end

    def render_languages
      render json: @languages, status: :ok
    end
  end
end
