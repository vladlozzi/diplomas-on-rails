class MainController < ApplicationController
  def init
    @files_in_uploads = Dir.entries(File.join(Rails.root.join('public', 'uploads').to_s))
  end

  def upload
    file_to_upload = params[:file_to_upload]
    unless file_to_upload.nil?
      File.open(Rails.root.join('public', 'uploads', file_to_upload.original_filename), 'wb') do |file|
        file.write(file_to_upload.read)
        redirect_to root_url
      end
    end
  end
end