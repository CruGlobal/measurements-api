# frozen_string_literal: true

namespace :erd do
  task exceptional_names: :environment do
    Rails.logger.level = Logger::ERROR
    Rails.application.eager_load!

    fn = ENV["MODEL_LIST"] || "doc/rest_of_the_models.txt"
    classes = File.read(fn).split("\n")

    ActiveRecord::Base.descendants.sort_by(&:to_s).each do |cl|
      cn = cl.to_s

      # By default, `classes` are to be ignored.
      # A different basename will invert the test and make `classes` a list to regard.
      next if (File.basename(fn) == "rest_of_the_models.txt") == classes.include?(cn) ||
        cn == "ApplicationRecord"

      sc = cl.superclass.to_s
      puts "#{cn} < #{sc}" if ["ApplicationRecord", "ActiveRecord::Base"].exclude?(sc)

      tn = cl.table_name
      puts "#{cn} table_name = #{tn}" if tn != cl.send(:compute_table_name)

      pk = cl.primary_key
      puts "#{cn} primary_key = #{pk}" if pk != "id"

      tnp = cl.table_name_prefix
      puts "#{cn} table_name_prefix = #{tnp}" if tnp.present?
    end
  end
end
