# frozen_string_literal: true
if Rails.env.test?
  CarrierWave.configure do |config|
    config.storage = :file
  end
else
  CarrierWave.configure do |config|
    config.storage = :aws
    config.aws_bucket = ENV.fetch('AWS_BUCKET')
    config.aws_acl = 'private'
    config.aws_authenticated_url_expiration = 1.day
    config.aws_credentials = {
      access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
      secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
      region: 'us-east-1'
    }
  end
end
