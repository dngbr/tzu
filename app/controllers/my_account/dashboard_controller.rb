module MyAccount
  class DashboardController < BaseController
    def index
      # Main dashboard data - combining both Review and CompanyReview models
      @company_reviews_count = @company.company_reviews.count
      @reviews_count = Review.joins(csv_upload: :user).where(csv_uploads: { user_id: current_user.id }).count
      @total_reviews = @company_reviews_count + @reviews_count

      @average_rating = calculate_average_rating
      @recent_reviews = @company.company_reviews.order(created_at: :desc).limit(5)
      @rating_distribution = calculate_rating_distribution
      @monthly_review_counts = reviews_by_month(6) # Last 6 months
      @sentiment_score = calculate_sentiment_score
      @analysis_rate = calculate_analysis_rate

      # Trends over time (last 6 months)
      @sentiment_trends = calculate_sentiment_trends(6)
      @rating_trends = calculate_rating_trends(6)
    end

    private

    def calculate_average_rating
      # Since only CompanyReview has ratings, we'll use only those for average rating
      @company.company_reviews.average(:rating).to_f.round(1) || 0.0
    end

    def calculate_rating_distribution
      distribution = {}

      # Since only CompanyReview has ratings, we'll use only those for rating distribution
      # but we'll calculate percentages based on total reviews from both models
      (1..5).each do |rating|
        count = @company.company_reviews.where(rating: rating).count
        percentage = @total_reviews > 0 ? (count.to_f / @total_reviews * 100).round : 0
        distribution[rating] = { count: count, percentage: percentage }
      end

      distribution
    end

    def reviews_by_month(months_count)
      result = {}

      # Create a range of months (most recent first)
      dates = months_count.downto(1).map { |n| n.months.ago.beginning_of_month }

      # For each month, count the reviews
      dates.each do |date|
        month_name = date.strftime("%b")
        start_date = date.beginning_of_month
        end_date = date.end_of_month

        count = @company.company_reviews.where(created_at: start_date..end_date).count
        result[month_name] = count
      end

      result
    end

    def calculate_sentiment_score
      # Calculate a sentiment score based on the sentiment field (positive, negative, neutral)
      # from both CompanyReview and Review models

      # Get CompanyReview sentiments
      company_reviews_with_sentiment = @company.company_reviews.where.not(sentiment: nil)
      company_positive_count = company_reviews_with_sentiment.where(sentiment: CompanyReview::SENTIMENTS[:positive]).count
      company_neutral_count = company_reviews_with_sentiment.where(sentiment: CompanyReview::SENTIMENTS[:neutral]).count
      company_negative_count = company_reviews_with_sentiment.where(sentiment: CompanyReview::SENTIMENTS[:negative]).count

      # Get Review sentiments from user's CSV uploads
      user_reviews = Review.joins(csv_upload: :user).where(csv_uploads: { user_id: current_user.id })
      user_reviews_with_sentiment = user_reviews.where.not(sentiment: nil)
      user_positive_count = user_reviews_with_sentiment.where(sentiment: Review::SENTIMENTS[:positive]).count
      user_neutral_count = user_reviews_with_sentiment.where(sentiment: Review::SENTIMENTS[:neutral]).count
      user_negative_count = user_reviews_with_sentiment.where(sentiment: Review::SENTIMENTS[:negative]).count

      # Combine counts
      positive_count = company_positive_count + user_positive_count
      neutral_count = company_neutral_count + user_neutral_count
      negative_count = company_negative_count + user_negative_count

      total = positive_count + neutral_count + negative_count

      if total > 0
        # Calculate a percentage score (0-100) where:
        # positive reviews = 100 points
        # neutral reviews = 50 points
        # negative reviews = 0 points
        score = ((positive_count * 100) + (neutral_count * 50)) / total
        score.round
      else
        # Return a default or placeholder value
        nil
      end
    end

    def calculate_analysis_rate
      # Calculate the percentage of reviews that have been analyzed from both models

      # Company reviews analysis
      company_total = @company.company_reviews.count
      company_analyzed = @company.company_reviews.where(analyzed: true).count

      # User's CSV upload reviews (all CSV upload reviews are considered analyzed)
      user_reviews = Review.joins(csv_upload: :user).where(csv_uploads: { user_id: current_user.id })
      user_total = user_reviews.count

      # Combined totals
      total = company_total + user_total
      analyzed = company_analyzed + user_total # All CSV reviews are considered analyzed

      return 0 if total == 0
      (analyzed.to_f / total * 100).round
    end

    def calculate_sentiment_trends(months_count)
      result = {}

      # Create a range of months (most recent first)
      dates = months_count.downto(1).map { |n| n.months.ago.beginning_of_month }

      # Initialize the result structure
      result = {
        months: [],
        positive: [],
        neutral: [],
        negative: []
      }

      # For each month, calculate sentiment distribution
      dates.each do |date|
        month_name = date.strftime("%b")
        start_date = date.beginning_of_month
        end_date = date.end_of_month

        # Get QR code reviews for this month
        monthly_reviews = @company.company_reviews.where(created_at: start_date..end_date)

        # Count sentiments
        positive_count = monthly_reviews.where(sentiment: CompanyReview::SENTIMENTS[:positive]).count
        neutral_count = monthly_reviews.where(sentiment: CompanyReview::SENTIMENTS[:neutral]).count
        negative_count = monthly_reviews.where(sentiment: CompanyReview::SENTIMENTS[:negative]).count

        # Add data to result
        result[:months] << month_name
        result[:positive] << positive_count
        result[:neutral] << neutral_count
        result[:negative] << negative_count
      end

      result
    end

    def calculate_rating_trends(months_count)
      result = {}

      # Get the current year only
      current_year = Date.today.year

      # Create a range of months for current year only (most recent first)
      dates = []
      months_count.downto(1).each do |n|
        date = n.months.ago.beginning_of_month
        dates << date if date.year == current_year
      end

      # Initialize the result structure
      result = {
        months: [],
        ratings: [],
        counts: []
      }

      # For each month, calculate average rating
      dates.each do |date|
        month_name = date.strftime("%b")
        start_date = date.beginning_of_month
        end_date = date.end_of_month

        # Get QR code reviews for this month
        monthly_reviews = @company.company_reviews.where(created_at: start_date..end_date)
        monthly_count = monthly_reviews.count

        # Calculate average rating for the month
        avg_rating = monthly_reviews.average(:rating).to_f.round(1) || 0.0

        # Add data to result
        result[:months] << month_name
        result[:ratings] << avg_rating
        result[:counts] << monthly_count
      end

      result
    end
  end
end
