# frozen_string_literal: true
require 'import'

class ImportWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_and_while_executing, retry: false

  def perform
    Import.new.import
  end
end
