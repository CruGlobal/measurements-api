# frozen_string_literal: true

module V5
  class MinistriesController < V5::BaseUserController
    include V5::MinistriesConcern[authorize: true]
  end
end
