source 'https://rubygems.org'
source 'https://gems.contribsys.com/' do
  gem 'sidekiq-pro'
end

gem 'rails-api'
gem 'active_model_serializers', git: 'https://github.com/rails-api/active_model_serializers.git'
gem 'puma'
gem 'newrelic_rpm'
gem 'rails-api-newrelic'
gem 'versionist'
gem 'rack-cors', require: 'rack/cors'
gem 'rollbar'
gem 'syslog-logger'
gem 'oj'
gem 'oj_mimic_json'
gem 'cru_lib', git: 'https://github.com/CruGlobal/cru_lib.git'
gem 'pg'
gem 'rubycas-client-rails'
gem 'xml-simple', require: 'xmlsimple'
gem 'sidekiq-unique-jobs'
gem 'redis-namespace'
gem 'sinatra', :require => nil

group :development, :test do
  gem 'dotenv-rails'
  gem 'guard-rubocop'
  gem 'guard-rspec'
  gem 'rspec-rails'
  gem 'spring'
  gem 'pry-rails'
  gem 'http_logger'
  gem 'awesome_print'
end

group :test do
  gem 'webmock'
  gem 'simplecov', require: false
  gem 'factory_girl_rails'
  gem 'shoulda', require: false
  gem 'rubocop'
  gem 'fakeredis', :require => 'fakeredis/rspec'
  gem 'coveralls', require: false
end
