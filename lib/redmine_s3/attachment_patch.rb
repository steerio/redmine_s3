require 'digest/md5'

module RedmineS3
  module AttachmentPatch
    extend ActiveSupport::Concern

    included do
      unloadable # Send unloadable so it will not be unloaded in development
      cattr_accessor :bucket, :s3_prefix
      remove_method :files_to_final_location, :delete_from_disk!
      after_save :upload_to_s3
    end
    
    def one_time_url
      s3_obj.url_for(:read).to_s
    end

    private

    def files_to_final_location
      # We don't do the actual upload here as that will need the record ID,
      # but we'll reuse this method name from the original code.

      if @temp_file && (@temp_file.size > 0)
        self.digest = case @temp_file
          when String then Digest::MD5.hexdigest(@temp_file)
          when IO     then Digest::MD5.new.file(@temp_file.path).hexdigest
        end
      end
      true
    end

    def upload_to_s3
      if @temp_file && (@temp_file.size > 0)
        update_column :disk_filename, "#{id}_#{filename}"
        logger.debug("Uploading to #{bucket.name}/#{s3_path}")
        s3_obj.write(@temp_file)
      end
      @temp_file = nil
      true
    end

    def delete_from_disk!
      logger.debug("Deleting #{bucket.name}/#{s3_path}")
      s3_obj.delete
    end

    def s3_obj
      bucket.objects[s3_path]
    end

    def s3_path
      "#{s3_prefix}#{disk_filename}"
    end
  end
end
