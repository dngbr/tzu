require_relative "../services/reviews_analyzer"

class TextProcessingJob
  include Sidekiq::Job

  def perform(csv_upload_id)
    csv_upload = CsvUpload.find_by(id: csv_upload_id)
    return unless csv_upload

    begin
      csv_upload.update(status: CsvUpload::STATUSES[:processing])

      reviews, ratings = process_text(csv_upload)
      reviews_text = reviews.join("\n\n")

      analyzer = ReviewsAnalyzer.new(reviews_text)
      analysis_response = analyzer.call

      # Check if we have parsed JSON in the response
      parsed_json = analysis_response["parsed_json"]

      if parsed_json.present?
        # Use the structured JSON response
        summary = parsed_json["summary"]
        insights = parsed_json["key_insights"] || parsed_json["insights"] || []
        recommendations = parsed_json["recommendations"] || []

        # Normalize sentiment to match allowed values
        raw_sentiment = parsed_json["sentiment"].to_s.downcase
        sentiment = case raw_sentiment
        when "positive"
                      "positive"
        when "negative"
                      "negative"
        else
                      "neutral"
        end

        # Store confidence score if available
        sentiment_confidence = parsed_json["sentiment_confidence"]
      else
        # Fallback to the old extraction methods
        summary = extract_summary(analysis_response)
        insights = extract_insights(analysis_response)
        recommendations = extract_recommendations(analysis_response)
        sentiment = extract_overall_sentiment(analysis_response)
      end

      sentiment_counts = analyze_sentiment_from_reviews(reviews, sentiment)

      # Create Analysis record
      analysis = csv_upload.create_analysis!(
        sentiment: sentiment,
        summary: summary,
        insights: insights,
        recommendations: recommendations,
        positive_count: sentiment_counts[:positive],
        negative_count: sentiment_counts[:negative],
        neutral_count: sentiment_counts[:neutral]
      )

      reviews.first(500).each do |review_text|
        review_sentiment = sentiment # Use overall sentiment for now
        csv_upload.reviews.create!(
          content: review_text,
          sentiment: review_sentiment
        )
      end

      csv_upload.update(status: CsvUpload::STATUSES[:completed])
    rescue => e
      Rails.logger.error("Error processing Text file #{csv_upload_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      csv_upload.update(status: CsvUpload::STATUSES[:failed])
    end
  end

  private

  def process_text(csv_upload)
    text_content = csv_upload.file.download
    reviews = []
    ratings = []

    # Try to determine the delimiter (newline, double newline, or custom separator)
    if text_content.include?("\n\n")
      # Double newline separator
      reviews = text_content.split("\n\n").map(&:strip).reject(&:empty?)
    elsif text_content.include?("---")
      # Custom separator
      reviews = text_content.split("---").map(&:strip).reject(&:empty?)
    else
      # Single newline separator
      reviews = text_content.split("\n").map(&:strip).reject(&:empty?)
    end

    # Look for ratings in the text (e.g., "Rating: 4" or "4/5 stars")
    reviews.each do |review|
      rating_match = review.match(/rating:\s*(\d+)|(\d+)\s*\/\s*[5|10]|(\d+)\s*stars?/i)
      if rating_match
        rating = rating_match.captures.compact.first.to_i
        ratings << rating if rating.between?(1, 5)
      end
    end

    [ reviews, ratings ]
  end

  # Extraction helpers for OpenAI response
  def extract_summary(response)
    content = response.dig("choices", 0, "message", "content").to_s
    if content =~ /Overall Summary:\s*(.*?)(?:\n{2,}|Key Insights:|Recommendations:|Overall Sentiment:)/m
      $1.strip
    else
      content.lines.first.to_s.strip
    end
  end

  def extract_insights(response)
    content = response.dig("choices", 0, "message", "content").to_s
    if content =~ /Key Insights:\s*(.*?)(?:\n(?:Recommendations:|Overall Sentiment:)|\z)/m
      block = $1
      # Extract lines that start with a dash, bullet, or number
      block.scan(/^\s*[-*•]\s+(.*)/).flatten.map(&:strip)
    else
      []
    end
  end

  def extract_recommendations(response)
    content = response.dig("choices", 0, "message", "content").to_s
    if content =~ /Recommendations:\s*(.*?)(?:\n{2,}|Overall Sentiment:)/m
      block = $1
      # Extract numbered list
      block.scan(/\d+\.\s+(.*)/).flatten.map(&:strip)
    else
      []
    end
  end

  def extract_overall_sentiment(response)
    content = response.dig("choices", 0, "message", "content").to_s
    if content =~ /Overall Sentiment:\s*(.*)$/i
      sentiment = $1.strip.downcase
      if sentiment.include?("positive")
        "positive"
      elsif sentiment.include?("negative")
        "negative"
      elsif sentiment.include?("mixed")
        "neutral"
      else
        sentiment
      end
    else
      "neutral"
    end
  end

  def analyze_sentiment_from_reviews(reviews, overall_sentiment)
    positive_count = 0
    negative_count = 0
    neutral_count = 0
    reviews.each do |review|
      if review.downcase.match?(/good|great|excellent|love|awesome|happy/)
        positive_count += 1
      elsif review.downcase.match?(/bad|terrible|awful|hate|disappointed|poor/)
        negative_count += 1
      else
        neutral_count += 1
      end
    end
    { positive: positive_count, negative: negative_count, neutral: neutral_count }
  end
end
