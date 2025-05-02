module MyAccount
  class CompanyReviewsController < ApplicationController
    skip_before_action :authenticate_user!, only: [:new, :create]
    before_action :set_company, only: [:new, :create]
    before_action :ensure_business_owner, only: [:index]
    
    def new
      @company_review = CompanyReview.new(rating: 3)
    end

    def create
      @company_review = @company.company_reviews.new(company_review_params)
      
      if @company_review.save
        # Store the saved review ID in flash to show thank you message
        flash[:thank_you] = true
        # Redirect to the same page to ensure a fresh state
        redirect_to review_company_path(company_id: @company.id)
      else
        render :new, status: :unprocessable_entity
      end
    end

    def show
      @company_review = CompanyReview.find(params[:id])
      @company = @company_review.company
    end
    
    def index
      @company = current_user.company
      if @company
        @company_reviews = @company.company_reviews.order(created_at: :desc).page(params[:page]).per(5)
        @can_analyze = CompanyReviewAnalysis.can_analyze?(@company)
        @analysis = @company.company_review_analyses.order(created_at: :desc).first
        
        # Calculate sentiment breakdown
        all_reviews = @company.company_reviews
        total_count = all_reviews.count
        
        if total_count > 0
          positive_reviews = all_reviews.where(sentiment: 'positive')
          neutral_reviews = all_reviews.where(sentiment: 'neutral')
          negative_reviews = all_reviews.where(sentiment: 'negative')
          
          @positive_count = positive_reviews.count
          @neutral_count = neutral_reviews.count
          @negative_count = negative_reviews.count
          
          @positive_percentage = ((positive_reviews.count.to_f / total_count) * 100).round
          @neutral_percentage = ((neutral_reviews.count.to_f / total_count) * 100).round
          @negative_percentage = ((negative_reviews.count.to_f / total_count) * 100).round
        else
          @positive_count = @neutral_count = @negative_count = 0
          @positive_percentage = @neutral_percentage = @negative_percentage = 0
        end
      else
        redirect_to my_profile_path, alert: t('company_reviews.no_company')
      end
    end
    
    def analyze
      @company = current_user.company
      
      if @company
        if CompanyReviewAnalysis.can_analyze?(@company)
          # Start a background job for analysis
          job_id = ReviewAnalysisJob.perform_async(@company.id)
          
          # Set initial status
          ReviewAnalysisJob.set_status(job_id, ReviewAnalysisJob::STATUS[:pending])
          
          # Return the job ID
          render json: { job_id: job_id, status: 'pending' }
        else
          render json: { error: t('company_reviews.analysis.not_allowed') }, status: :unprocessable_entity
        end
      else
        render json: { error: t('company_reviews.no_company') }, status: :unprocessable_entity
      end
    end
    
    def check_analysis_status
      job_id = params[:job_id]
      
      if job_id.present?
        status_data = ReviewAnalysisJob.get_status(job_id)
        
        if status_data[:status] == ReviewAnalysisJob::STATUS[:completed]
          # Refresh the analysis data
          @company = current_user.company
          @analysis = @company.company_review_analyses.order(created_at: :desc).first
          
          render json: { 
            status: status_data[:status], 
            completed: true,
            redirect_to: my_account_my_reviews_path
          }
        elsif status_data[:status] == ReviewAnalysisJob::STATUS[:failed]
          render json: { 
            status: status_data[:status], 
            completed: true, 
            error: status_data[:result].try(:[], 'error') || t('company_reviews.analysis.failed')
          }
        else
          render json: { status: status_data[:status], completed: false }
        end
      else
        render json: { error: 'No job ID provided' }, status: :bad_request
      end
    end
    
    private
    
    def set_company
      @company = Company.find(params[:company_id])
      # Set the locale based on URL parameter first, then company's preferred language
      I18n.locale = if params[:locale].present?
                      params[:locale]
                    elsif @company.preferred_language.present?
                      @company.preferred_language
                    else
                      I18n.default_locale
                    end
    rescue ActiveRecord::RecordNotFound
      redirect_to root_path, alert: t('company_reviews.company_not_found')
    end
    
    def company_review_params
      params.require(:company_review).permit(:reviewer_name, :reviewer_phone, :content, :rating)
    end
    
    def ensure_business_owner
      unless current_user.business_owner?
        redirect_to my_profile_path, alert: t('company_reviews.business_owner_required')
      end
    end
  end
end