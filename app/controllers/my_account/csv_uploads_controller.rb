module MyAccount
  class CsvUploadsController < ApplicationController
    before_action :!
    before_action :set_csv_upload, only: [:show]
    
    def index
      @csv_uploads = current_user.csv_uploads.order(created_at: :desc)
    end
    
    def my_uploads
      @csv_uploads = current_user.csv_uploads.order(created_at: :desc)
    end
    
    def show
      # Ensure the user can only view their own uploads
      authorize_user_resource(@csv_upload)
    end
    
    def new
      @csv_upload = CsvUpload.new
    end
    
    def create
      @csv_upload = current_user.csv_uploads.build(csv_upload_params)
      
      if @csv_upload.save
        # Enqueue the Sidekiq job to process the CSV
        CsvProcessingJob.perform_async(@csv_upload.id)
        
        redirect_to csv_uploads_path, notice: "CSV file was successfully uploaded and is being processed."
      else
        render :new, status: :unprocessable_entity
      end
    end
    
    private
    
    def set_csv_upload
      @csv_upload = CsvUpload.find(params[:id])
    end
    
    def csv_upload_params
      params.require(:csv_upload).permit(:name, :file)
    end
    
    def authorize_user_resource(resource)
      unless resource.user == current_user
        redirect_to csv_uploads_path, alert: "You are not authorized to view this resource."
      end
    end
  end
end
