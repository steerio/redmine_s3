module RedmineS3
  class Railtie < Rails::Railtie
    config.to_prepare do
      if File.exist?(cfg = "#{Rails.root}/config/s3.yml")
        options = YAML::load(ERB.new(IO.read(cfg)).result).try :[], Rails.env
        akid  = options['access_key_id']
        sakid = options['secret_access_key']
        bucket = options['bucket']
      else
        akid  = ENV['AWS_ACCESS_KEY_ID']
        sakid = ENV['AWS_SECRET_ACCESS_KEY']
        bucket = ENV['AWS_S3_BUCKET']
      end

      if akid && sakid && bucket
        require_dependency 'attachment'
        require_dependency 'application_controller'
        require_dependency 'attachments_controller'
        require 'aws/s3'
        require 'redmine_s3/attachment_patch'
        require 'redmine_s3/attachments_controller_patch'
        Attachment.send :include, AttachmentPatch
        AttachmentsController.send :include, AttachmentsControllerPatch

        # We accept a base directory as part of the bucket name
        bucket, path = bucket.split('/', 2)

        Attachment.bucket = AWS::S3.new(
          :access_key_id => akid,
          :secret_access_key => sakid).buckets[bucket]
        Attachment.s3_prefix = path && "#{path}/"
        Rails.logger.debug 'Configured S3 access.'

        Redmine::Plugin.register :redmine_s3_attachments do
          name 'S3'
          author 'Chris Dell, Roland Venesz'
          description 'Use Amazon S3 as a storage engine for attachments'
          version '0.0.4'
        end
      else
        Rails.logger.debug 'NO S3 CONFIGURATION: Attachments are saved locally.'
      end
    end
  end
end
