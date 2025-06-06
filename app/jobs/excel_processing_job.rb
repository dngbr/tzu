require_relative '../services/reviews_analyzer'
require 'roo'

class ExcelProcessingJob
  include Sidekiq::Job

  def perform(csv_upload_id)
    csv_upload = CsvUpload.find_by(id: csv_upload_id)
    return unless csv_upload

    begin
      csv_upload.update(status: CsvUpload::STATUSES[:processing])

      reviews, ratings = process_excel(csv_upload)
      reviews_text = reviews.join("\n\n")

      analyzer = ReviewsAnalyzer.new(reviews_text)
      analysis_response = analyzer.call
      
      # Check if we have parsed JSON in the response
      parsed_json = analysis_response["parsed_json"]
      
      if parsed_json.present?
        # Use the structured JSON response
        summary = parsed_json['summary']
        insights = parsed_json['key_insights'] || parsed_json['insights'] || []
        recommendations = parsed_json['recommendations'] || []
        
        # Normalize sentiment to match allowed values
        raw_sentiment = parsed_json['sentiment'].to_s.downcase
        sentiment = case raw_sentiment
                    when 'positive'
                      'positive'
                    when 'negative'
                      'negative'
                    else
                      'neutral'
                    end
        
        # Store confidence score if available
        sentiment_confidence = parsed_json['sentiment_confidence']
      else
        # Fallback to the old extraction methods
        summary = extract_summary(analysis_response)
        insights = extract_insights(analysis_response)
        recommendations = extract_recommendations(analysis_response)
        sentiment = extract_overall_sentiment(analysis_response)
      end

      if ratings.present? && ratings.length == reviews.length
        sentiment_counts = analyze_sentiment_from_ratings(ratings)
      else
        sentiment_counts = analyze_sentiment_from_reviews(reviews, sentiment)
      end

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
      Rails.logger.error("Error processing Excel #{csv_upload_id}: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      csv_upload.update(status: CsvUpload::STATUSES[:failed])
    end
  end

  private

  def process_excel(csv_upload)
    reviews = []
    ratings = []

    # Download the file and open it with Roo
    temp_file = Tempfile.new(['excel', File.extname(csv_upload.file.filename.to_s)])
    temp_file.binmode
    temp_file.write(csv_upload.file.download)
    temp_file.rewind

    # Use Roo to open the Excel file
    excel = Roo::Spreadsheet.open(temp_file.path)
    sheet = excel.sheet(0) # Get the first sheet

    # Get headers
    headers = sheet.row(1).map(&:to_s).map(&:downcase)

    # Process each row
    (2..sheet.last_row).each do |row_num|
      row_data = sheet.row(row_num)
      review_text = nil
      rating = nil

      # Look for review text in common column names
      review_column_index = find_column_index(headers, ['review', 'comment', 'feedback', 'text', 'content'])
      review_text = row_data[review_column_index] if review_column_index

      # Look for rating in common column names
      rating_column_index = find_column_index(headers, ['rating', 'score', 'stars', 'grade'])
      rating = row_data[rating_column_index].to_i if rating_column_index && row_data[rating_column_index].present?

      # If no review text found in expected columns, take first non-empty cell
      if review_text.nil?
        row_data.each_with_index do |value, index|
          if value.present?
            review_text = value.to_s
            break
          end
        end
      end

      if review_text.present?
        reviews << review_text
        ratings << rating if rating.present?
      end
    end

    temp_file.close
    temp_file.unlink

    [reviews, ratings]
  end

  def find_column_index(headers, possible_names)
    possible_names.each do |name|
      index = headers.find_index { |h| h.include?(name) }
      return index if index
    end
    nil
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

  def analyze_sentiment_from_ratings(ratings)
    positive_count = 0
    negative_count = 0
    neutral_count = 0
    ratings.each do |rating|
      if rating >= 4
        positive_count += 1
      elsif rating <= 2
        negative_count += 1
      else
        neutral_count += 1
      end
    end
    { positive: positive_count, negative: negative_count, neutral: neutral_count }
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
