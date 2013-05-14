module RedmineS3
  module AttachmentsControllerPatch
    extend ActiveSupport::Concern

    included do
      unloadable # Send unloadable so it will not be unloaded in development
      before_filter :redirect_to_s3, :except => [:destroy, :upload]
      skip_before_filter :file_readable
    end
    
    def redirect_to_s3
      if @attachment.container.is_a?(Version) || @attachment.container.is_a?(Project)
        @attachment.increment_download
      end
      redirect_to @attachment.one_time_url
    end
  end
end
