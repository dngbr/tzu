# == Schema Information
#
# Table name: company_reviews
#
#  id             :integer          not null, primary key
#  company_id     :integer          not null
#  reviewer_name  :string
#  reviewer_phone :string
#  content        :text
#  sentiment      :string
#  analyzed       :boolean          default("0")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class CompanyReview < ApplicationRecord
  belongs_to :company
  
  validates :content, presence: true
  validates :reviewer_name, presence: true
  validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5 }
  
  # Sentiment constants
  SENTIMENTS = {
    positive: 'positive',
    negative: 'negative',
    neutral: 'neutral'
  }
  
  # Analyze sentiment based on rating
  def analyze_sentiment
    return if analyzed?
    
    # Simple sentiment analysis based on rating
    self.sentiment = if rating >= 4
                      SENTIMENTS[:positive]
                    elsif rating <= 2
                      SENTIMENTS[:negative]
                    else
                      SENTIMENTS[:neutral]
                    end
    self.analyzed = true
    save
  end
  
  # Class methods for analytics
  def self.sentiment_distribution
    counts = group(:sentiment).count
    {
      positive: counts[SENTIMENTS[:positive]] || 0,
      negative: counts[SENTIMENTS[:negative]] || 0,
      neutral: counts[SENTIMENTS[:neutral]] || 0,
      not_analyzed: where(analyzed: false).count
    }
  end
  
  def self.rating_distribution
    group(:rating).count
  end
  
  def self.average_rating
    average(:rating)&.round(1) || 0
  end
  
  def self.reviews_by_month(months = 6)
    date_range = months.months.ago.beginning_of_month..Time.current.end_of_month
    
    reviews = where(created_at: date_range)
             .group("strftime('%Y-%m', created_at)")
             .count
    
    # Fill in missing months with zero counts
    result = {}
    date_range.by_month.each do |date|
      month_key = date.strftime('%Y-%m')
      result[month_key] = reviews[month_key] || 0
    end
    
    result
  end
  
  validates :sentiment, inclusion: { in: SENTIMENTS.values }, allow_nil: true
  
  # Default values
  after_initialize :set_defaults, if: :new_record?
  
  # Send notification for all reviews
  after_create :notify_company_of_review
  
  # Scopes for filtering by sentiment
  scope :positive, -> { where(sentiment: SENTIMENTS[:positive]) }
  scope :negative, -> { where(sentiment: SENTIMENTS[:negative]) }
  scope :neutral, -> { where(sentiment: SENTIMENTS[:neutral]) }
  
  # Scope for unanalyzed reviews
  scope :unanalyzed, -> { where(analyzed: false) }
  
  private
  
  def set_defaults
    self.analyzed ||= false
  end
  
  def notify_company_of_review
    # Determine if this is a negative review
    is_negative = rating <= 2 || sentiment == SENTIMENTS[:negative]
    
    # Create notification for all reviews, with different actions for negative vs regular
    Notification.create(
      recipient: company,
      action: is_negative ? "negative_review" : "new_review",
      data: {
        rating: rating,
        content_preview: content.truncate(100),
        reviewer_name: reviewer_name,
        is_negative: is_negative,
        review_id: id
      }
    )
  end
end
