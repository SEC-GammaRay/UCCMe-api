# frozen_string_literal: true

require 'aws-sdk-s3'

# Helper module for uploading files to AWS S3
module FileStorageHelper
  def self.config
    UCCMe::Api.config
  end

  def self.upload(file:, filename:) # rubocop:disable Metrics/MethodLength
    bucket = config.AWS_BUCKET
    key = "#{config.AWS_PREFIX}/#{filename}"

    s3 = Aws::S3::Resource.new(
      access_key_id: config.AWS_ACCESS_KEY_ID,
      secret_access_key: config.AWS_SECRET_ACCESS_KEY,
      region: config.AWS_REGION
    )

    content_type = Rack::Mime.mime_type(File.extname(filename), 'application/octet-stream')

    obj = s3.bucket(bucket).object(key)
    obj.put(body: file,
            content_type: content_type)

    key
  end

  def self.presigned_url(s3_path:, expires_in: 3600) # rubocop:disable Metrics/MethodLength
    s3 = Aws::S3::Client.new(
      access_key_id: config.AWS_ACCESS_KEY_ID,
      secret_access_key: config.AWS_SECRET_ACCESS_KEY,
      region: config.AWS_REGION
    )

    signer = Aws::S3::Presigner.new(client: s3)
    signer.presigned_url(:get_object,
                         bucket: config.AWS_BUCKET,
                         key: s3_path,
                         response_content_disposition: 'inline', # 這行讓它「在頁面內預覽」
                         expires_in: expires_in)
  end
end
