# frozen_string_literal: true
require 'csv'
require 'tree_order'
require 'import_mappings'
require 'aws-sdk-core'

# For importing from the old SQL Server database that has been dumped to CSV,
# and uploaded to S3 in the folder sql_server_csv_dump.
class Import
  def initialize
    @empty_objects ||= {}
  end

  def import
    ImportMappings::MAPPINGS.each do |mapping|
      import_model(*mapping)
    end
  end

  private

  def import_model(klass, csv_table, field_mapping, object_tap_proc = nil, rows_map_proc = nil)
    start_count = klass.count
    Sidekiq.logger.info("\nImporting #{klass.name} from #{csv_table}.csv ...")
    csv_rows(csv_table, rows_map_proc).each do |row|
      import_object(klass, row, field_mapping, object_tap_proc)
    end
    num_imported = klass.count - start_count
    update_id_sequence(klass)
    Sidekiq.logger.info("Imported #{num_imported} #{klass.table_name}.")
  end

  def update_id_sequence(klass)
    table = klass.table_name
    max_id = klass.order(id: :desc).pluck(:id).first
    klass.connection.execute("ALTER SEQUENCE #{table}_id_seq RESTART WITH #{max_id + 1}")
  end

  def import_object(klass, row, field_mapping, object_tap_proc)
    object = new_with_field_mapping(klass, row, field_mapping)
    object_tap_proc.call(object, row) if object_tap_proc.present?
    object.save!
  rescue SkipRecord
    # We are intentionally skipping this record so do nothing
    nil
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique,
         ActiveRecord::RecordNotFound, ActiveRecord::StatementInvalid => e
    Sidekiq.logger.info("Error importing row #{row}: #{e}")
  end

  def new_with_field_mapping(klass, row, field_mapping)
    args = matching_key_args(klass, row).merge(mapped_values(row, field_mapping))
    klass.new(args)
  end

  def mapped_values(row, field_mapping)
    Hash[field_mapping.map { |from, to| [to, row[from]] }]
  end

  def matching_key_args(klass, row)
    associations = klass.reflect_on_all_associations.map(&:name)
    matching_args = {}
    object = empty_object(klass)
    row.headers.each do |field|
      next unless object.respond_to?("#{field}=")
      next if field.in?(associations)
      matching_args[field] = field_value(klass, field, row)
    end
    matching_args
  end

  def field_value(klass, field, row)
    val = row[field]
    if enum_field?(klass, field)
      val.blank? ? nil : klass.send(pluralized_field(field)).invert[val.to_i]
    else
      val
    end
  end

  def enum_field?(klass, field)
    pluralized = pluralized_field(field)
    klass.respond_to?(pluralized) && klass.send(pluralized).is_a?(Hash)
  end

  def pluralized_field(field)
    field.to_s.pluralize.to_sym
  end

  def empty_object(klass)
    @empty_objects[klass] ||= klass.new
  end

  def csv_rows(table, rows_map_proc = nil)
    rows = CSV.parse(csv_text(table), headers: true, header_converters: :symbol)
    return rows if rows_map_proc.blank?
    rows_map_proc.call(rows)
  end

  def csv_text(table)
    s3.get_object(key: "sql_server_csv_dump/#{table}.csv", bucket_name: ENV.fetch('S3_BUCKET')).body
  end

  def s3
    @s3 ||= ::Aws::S3::Client.new(
      access_key_id: ENV.fetch('S3_ACCESS_KEY_ID'),
      secret_access_key: ENV.fetch('S3_SECRET_ACCESS_KEY')
    )
  end

  class SkipRecord < StandardError
  end
end
