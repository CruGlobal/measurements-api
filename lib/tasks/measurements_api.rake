namespace :measurements_api do
  # Call this as follows:
  # bundle exec rake measurements_api:import_data[exported_csv_folder]
  task :import_csv_data, [:csv_folder] => :environment do |_task, args|
    require_relative '../import'
    Rails.logger = Logger.new(STDOUT)
    Rails.logger.formatter = ActiveSupport::Logger::SimpleFormatter.new
    Import.new(args[:csv_folder]).import
  end
end
