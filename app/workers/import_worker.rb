# frozen_string_literal: true

require "import"

# Console command to re-run import. This will delete all existing data.
# def rerun_import
#   Dir['./lib/*.rb'].each { |file| load file };
#   ImportMappings::MAPPINGS.reverse.each do |mapping|
#     klass = mapping.first
#     klass.delete_all
#   end
#   ImportWorker.perform_async
# end

class ImportWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_and_while_executing, retry: false

  def perform
    Import.new.import
  end
end
