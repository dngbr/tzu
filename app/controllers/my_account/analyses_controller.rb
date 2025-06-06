module MyAccount
  class AnalysesController < ApplicationController
    before_action :set_analysis, only: [:show]

    def show
      @csv_upload = @analysis.csv_upload
      authorize_user_resource(@csv_upload)

      # Get paginated reviews for this CSV upload
      @reviews = @csv_upload.reviews.page(params[:page]).per(10)
    end

    private

    def set_analysis
      @analysis = Analysis.find(params[:id])
  end

    def authorize_user_resource(resource)
      unless resource.user == current_user
        redirect_to my_account_csv_uploads_path, alert: "You are not authorized to view this resource."
      end
    end
  end
end
