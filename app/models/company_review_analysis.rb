class CompanyReviewAnalysis < ApplicationRecord
  belongs_to :company
  
  # Store insights and recommendations as arrays
  serialize :insights, coder: YAML
  serialize :recommendations, coder: YAML
  
  # Validations
  validates :company, presence: true
  validates :reviews_count, presence: true
  validates :last_analyzed_at, presence: true
  
  # Sentiments
  SENTIMENTS = {
    positive: 'positive',
    negative: 'negative',
    neutral: 'neutral'
  }
  
  validates :sentiment, inclusion: { in: SENTIMENTS.values }, allow_nil: true
  
  # Check if analysis can be performed
  def self.can_analyze?(company)
    current_review_count = company.company_reviews.count
    last_analysis = company.company_review_analyses.order(created_at: :desc).first
    
    # Allow analysis if:
    # 1. There's no previous analysis, or
    # 2. There are new reviews since the last analysis
    return true if last_analysis.nil?
    return current_review_count > last_analysis.reviews_count
  end
  
  # Perform analysis on company reviews
  def self.perform_analysis(company)
    # Check if analysis can be performed
    return false unless can_analyze?(company)
    
    # Get all review content
    reviews = company.company_reviews
    review_texts = reviews.map(&:content)
    
    # Skip if no reviews
    return false if review_texts.empty?
    
    # Use the ReviewsAnalyzer service with the company's preferred language
    language = company.preferred_language.present? ? company.preferred_language : 'en'
    analyzer = ReviewsAnalyzer.new(review_texts.join("\n\n"), language)
    response = analyzer.call
    
    # Get the parsed JSON from the response
    parsed_json = response["parsed_json"]
    
    # Extract data from the parsed JSON response
    if parsed_json.present?
      # Use the structured JSON response
      summary = parsed_json['summary']
      insights = parsed_json['key_insights'] || parsed_json['insights'] || []
      recommendations = parsed_json['recommendations'] || []
      sentiment_value = parsed_json['sentiment']
      sentiment_confidence = parsed_json['sentiment_confidence']
      
      # If we have categorized insights, store them for potential future use
      categorized_insights = parsed_json['categorized_insights']
    else
      # Fallback to the old parsing method
      content = response.dig("choices", 0, "message", "content")
      summary, insights, recommendations, sentiment_value = parse_analysis_response(content)
    end
    
    # Determine sentiment based on individual reviews
    positive_count = 0
    neutral_count = 0
    negative_count = 0
    
    # First update individual reviews with their sentiment
    reviews.each do |review|
      # Determine sentiment based on rating
      review_sentiment = if review.rating >= 4
                         'positive'
                       elsif review.rating <= 2
                         'negative'
                       else
                         'neutral'
                       end
      
      # Update the review
      review.update(analyzed: true, sentiment: review_sentiment)
      
      # Count sentiments for overall analysis
      case review_sentiment
      when 'positive'
        positive_count += 1
      when 'neutral'
        neutral_count += 1
      when 'negative'
        negative_count += 1
      end
    end
    
    # Determine overall sentiment
    overall_sentiment = if parsed_json.present? && sentiment_value.present?
                        # Use the sentiment from the parsed JSON if available
                        case sentiment_value.to_s.downcase
                        when 'positive'
                          SENTIMENTS[:positive]
                        when 'negative'
                          SENTIMENTS[:negative]
                        else
                          SENTIMENTS[:neutral]
                        end
                      elsif positive_count > neutral_count && positive_count > negative_count
                        SENTIMENTS[:positive]
                      elsif negative_count > neutral_count && negative_count > positive_count
                        SENTIMENTS[:negative]
                      else
                        SENTIMENTS[:neutral]
                      end
    
    # Create a new analysis record
    analysis = company.company_review_analyses.create(
      reviews_count: reviews.count,
      summary: summary,
      insights: insights,
      recommendations: recommendations,
      sentiment: overall_sentiment,
      last_analyzed_at: Time.current
    )
    
    analysis
  end
  
  private
  
  # Parse the analysis response from the AI
  def self.parse_analysis_response(content)
    # Default values
    summary = ""
    insights = []
    recommendations = []
    sentiment = SENTIMENTS[:neutral]
    
    # Simple parsing based on expected format
    sections = content.split(/\d+\.\s/).reject(&:blank?)
    
    # Extract data if available
    if sections[0].present?
      # Clean up summary by removing redundant labels
      summary = sections[0].strip
                          .sub(/^(Summary|Rezumat)\s*:\s*/i, '')
                          .sub(/^(Overall\s+Summary|Rezumat\s+General)\s*:\s*/i, '')
    end
    
    if sections[1].present?
      # Extract bullet points for insights
      bullet_points = sections[1].strip.split(/•|-|\*/).map(&:strip).reject(&:blank?)
      insights = clean_list_items(bullet_points.take(5))
    end
    
    if sections[2].present?
      # Clean up the recommendations section first by removing section headers
      cleaned_section = sections[2].strip
                                  .sub(/^(Recommendations|Recomand[aă]ri)\s*:\s*/i, '')
                                  .sub(/^(Prioritizare\s+recomand[aă]ri|Prioritized\s+recommendations)\s*:\s*/i, '')
      
      # Extract bullet points for recommendations
      bullet_points = cleaned_section.split(/•|-|\*/).map(&:strip).reject(&:blank?)
      recommendations = clean_list_items(bullet_points.take(3))
    end
    
    if sections[3].present?
      # Extract sentiment
      sentiment_text = sections[3].strip.downcase
      sentiment = if sentiment_text.include?('positive') || sentiment_text.include?('pozitiv')
                    SENTIMENTS[:positive]
                  elsif sentiment_text.include?('negative') || sentiment_text.include?('negativ')
                    SENTIMENTS[:negative]
                  else
                    SENTIMENTS[:neutral]
                  end
    end
    
    [summary, insights, recommendations, sentiment]
  end
  
  # Clean list items by removing prefixes like "Insight 1:", "Observație Cheie 2:", etc.
  def self.clean_list_items(items)
    items.map do |item|
      # More precise pattern matching for prefixes only
      # English prefixes
      if item =~ /^(Key\s+)?(Insight|Observation)\s*(\d+)?\s*:\s*/i
        item = item.sub(/^(Key\s+)?(Insight|Observation)\s*(\d+)?\s*:\s*/i, '')
      elsif item =~ /^Recommendation\s*(\d+)?\s*:\s*/i
        item = item.sub(/^Recommendation\s*(\d+)?\s*:\s*/i, '')
      # Priority labels in English
      elsif item =~ /^Priority\s*(\d+)\s*:\s*/i
        item = item.sub(/^Priority\s*(\d+)\s*:\s*/i, '')
      # Romanian prefixes
      elsif item =~ /^Observa[țţ]ie(\s+Cheie)?\s*(\d+)?\s*:\s*/i
        item = item.sub(/^Observa[țţ]ie(\s+Cheie)?\s*(\d+)?\s*:\s*/i, '')
      elsif item =~ /^Recomandare\s*(\d+)?\s*:\s*/i
        item = item.sub(/^Recomandare\s*(\d+)?\s*:\s*/i, '')
      # Priority labels in Romanian
      elsif item =~ /^Prioritatea\s*(\d+)\s*:\s*/i
        item = item.sub(/^Prioritatea\s*(\d+)\s*:\s*/i, '')
      end
      
      # Capitalize first letter if needed
      item = item[0].upcase + item[1..-1] if item.length > 0
      
      item
    end
  end
end
