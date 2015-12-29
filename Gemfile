source 'https://rubygems.org'

# gem 'rails'
gem 'rails-api'
gem 'active_model_serializers', git: 'git://github.com/rails-api/active_model_serializers.git'
gem 'puma'
gem 'newrelic_rpm'
gem 'rails-api-newrelic'
gem 'versionist'
gem 'rack-cors', require: 'rack/cors'
gem 'rollbar'
gem 'syslog-logger'
gem 'oj'
gem 'oj_mimic_json'
gem 'cru_lib', '~> 0.0.5'
gem 'pg'
gem 'rubycas-client-rails'
gem 'xml-simple', require: 'xmlsimple'

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
  gem 'rubocop', '~> 0.34.0'
end
