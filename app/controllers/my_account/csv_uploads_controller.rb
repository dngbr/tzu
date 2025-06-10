module MyAccount
  class CsvUploadsController < ApplicationController
    before_action :authenticate_user!
    before_action :set_csv_upload, only: [ :show ]

    def index
      @csv_uploads = current_user.csv_uploads.order(created_at: :desc)
      @csv_upload = CsvUpload.new # For the upload modal form
    end

    def my_uploads
      @csv_uploads = current_user.csv_uploads.order(created_at: :desc)
      @csv_upload = CsvUpload.new # For the upload modal form
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
        # Determine the file type and enqueue the appropriate job
        file_extension = File.extname(@csv_upload.file.filename.to_s).downcase

        case file_extension
        when ".csv"
          CsvProcessingJob.perform_async(@csv_upload.id)
        when ".xlsx", ".xls"
          ExcelProcessingJob.perform_async(@csv_upload.id)
        when ".txt"
          TextProcessingJob.perform_async(@csv_upload.id)
        when ".json"
          JsonProcessingJob.perform_async(@csv_upload.id)
        else
          # Default to CSV processing for unknown formats
          CsvProcessingJob.perform_async(@csv_upload.id)
        end

        respond_to do |format|
          format.html { redirect_to my_account_my_uploads_path, notice: "File was successfully uploaded and is being processed." }
          format.turbo_stream { redirect_to my_account_my_uploads_path, notice: "File was successfully uploaded and is being processed." }
        end
      else
        respond_to do |format|
          format.html { render :new, status: :unprocessable_entity }
          format.turbo_stream do
            @csv_uploads = current_user.csv_uploads.order(created_at: :desc)
            render :index, status: :unprocessable_entity
          end
        end
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
        redirect_to my_account_csv_uploads_path, alert: "You are not authorized to view this resource."
      end
    end
  end
end
