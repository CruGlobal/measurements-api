# frozen_string_literal: true
if Rails.env.test?
  CarrierWave.configure do |config|
    config.storage = :file
  end
else
  CarrierWave.configure do |config|
    config.fog_credentials = {
      provider: 'AWS',
      aws_access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
      aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY')
    }
    config.fog_directory = ENV.fetch('AWS_BUCKET')
    config.fog_public = false
    config.fog_attributes = { 'x-amz-storage-class' => 'REDUCED_REDUNDANCY' }
    # X-Amz-Expires must be less than a week (in seconds); that is,
    # the given X-Amz-Expires must be less than 604800 seconds
    config.fog_authenticated_url_expiration = 1.day
    config.storage :fog
  end
end
