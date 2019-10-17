source "https://rubygems.org"
source "https://gems.contribsys.com/" do
  gem "sidekiq-pro", "3.1.0"
end
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "2.6.5"

gem "rake", "~> 11.1.1"
gem "rails", "~> 5.2.3"
gem "active_model_serializers", git: "https://github.com/rails-api/active_model_serializers.git"
gem "puma", "~> 3.11"
gem "newrelic_rpm"
gem "versionist"
gem "rollbar"
gem "syslog-logger"
gem "oj"
gem "oj_mimic_json"
gem "cru-auth-lib", "~> 0.1.0"
gem "pg"
gem "rubycas-client-rails"
gem "xml-simple", require: "xmlsimple"
gem "sidekiq", "4.1.1"
gem "sidekiq-unique-jobs", "4.0.18"
gem "sidekiq-cron"
gem "redis-rails"
gem "redis-namespace"
gem "sinatra", require: nil
gem "auto_strip_attributes", "~> 2.0"
gem "arel"
gem "consul"
gem "assignable_values"
gem "awesome_nested_set"
gem "global_registry"
gem "carrierwave-aws"
gem "will_paginate"
gem "ddtrace"
gem "dogstatsd-ruby"
gem "bootsnap", ">= 1.1.0", require: false
gem "ougai", "~> 1.7"

group :development, :test do
  gem "brakeman"
  gem "bundler-audit"
  gem "dotenv-rails"
  gem "guard-rubocop"
  gem "guard-rspec"
  gem "rspec-rails"
  gem "spring"
  gem "spring-commands-rspec"
  gem "pry-rails"
  gem "pry-byebug"
  gem "http_logger"
  gem "awesome_print"
  gem "rack-cors", require: "rack/cors"
  gem "standard"
end

group :test do
  gem "webmock"
  gem "rspec-sidekiq"
  gem "simplecov", require: false
  gem "factory_girl_rails"
  gem "shoulda", require: false
  gem "rspec-json_expectations", require: "rspec/json_expectations"
  gem "rubocop"
  gem "mock_redis"
  gem "fakeredis", require: "fakeredis/rspec"
  gem "coveralls", require: false
end

# add this at the end so it plays nice with pry
gem "marco-polo"
