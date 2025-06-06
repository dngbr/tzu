require 'fuzzy_match'
require 'matrix'

class ReviewsAnalyzer
  REVIEWS_DATA = [
    [
      "The service was excellent! The staff was very friendly and attentive.",
      "Food was delicious but the wait time was too long.",
      "I love this place! Will definitely come back again.",
      "The quality of the products has gone down recently. Not as good as it used to be.",
      "Amazing experience from start to finish. Highly recommend!",
      "Average service, nothing special to write home about.",
      "Disappointed with my recent purchase. The item was damaged when it arrived.",
      "Great customer service! They resolved my issue quickly and efficiently.",
      "The staff was rude and unhelpful. Will not be returning.",
      "Decent experience overall, but a bit overpriced for what you get.",
      "Absolutely fantastic! Exceeded all my expectations.",
      "The product quality is inconsistent. Sometimes great, sometimes not so much.",
      "Very professional and knowledgeable staff. Made me feel valued as a customer.",
      "Slow response time to my inquiries. Had to follow up multiple times.",
      "Best service I've ever received! The attention to detail was impressive.",
      "This was an amazing experience"
    ],
    [5, 3, 5, 2, 5, 3, 1, 4, 1, 3, 5, 3, 4, 2, 5, 5]
  ]

  # Language-specific role and focus translations
  LANGUAGE_TRANSLATIONS = {
    'en' => {
      customer_experience: {
        role: "Customer Experience Analyst",
        focus: "customer satisfaction, emotional responses, and service quality"
      },
      operational_efficiency: {
        role: "Operational Efficiency Expert",
        focus: "process bottlenecks, staff performance, and resource allocation"
      },
      market_positioning: {
        role: "Market Positioning Strategist",
        focus: "competitive advantages, pricing perception, and brand reputation"
      }
    },
    'ro' => {
      customer_experience: {
        role: "Analist de Experiență a Clienților",
        focus: "satisfacția clienților, răspunsurile emoționale și calitatea serviciilor"
      },
      operational_efficiency: {
        role: "Expert în Eficiență Operațională",
        focus: "blocaje de proces, performanța personalului și alocarea resurselor"
      },
      market_positioning: {
        role: "Strateg de Poziționare pe Piață",
        focus: "avantaje competitive, percepția prețurilor și reputația brandului"
      }
    }
  }

  def initialize(reviews = nil, language = 'en')
    if reviews.present?
      @reviews_text = reviews
    else
      # WE USE THIS AS A MOCK DATA WHEN NO REVIEWS ARE PROVIDED
      reviews, ratings = REVIEWS_DATA
      @reviews_text = reviews.join("\n\n")
    end
    @client = OpenAI::Client.new
    @perspective_results = {}
    @language = language.downcase
    @language = 'en' unless ['en', 'ro'].include?(@language) # Default to English if language not supported
  end

  def call
    # Perform analysis from each perspective
    analyze_from_all_perspectives
    
    # Synthesize the results from all perspectives
    synthesize_perspectives
  end

  private

  def analyze_from_all_perspectives
    perspectives = LANGUAGE_TRANSLATIONS[@language]
    perspectives.each do |perspective_key, perspective_data|
      @perspective_results[perspective_key] = analyze_from_perspective(perspective_key, perspective_data)
    end
  end

  def analyze_from_perspective(perspective_key, perspective_data)
    prompt = generate_perspective_prompt(perspective_data[:role], perspective_data[:focus])
    
    response = @client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: generate_system_prompt(perspective_data[:role], perspective_data[:focus]) },
          { role: "user", content: prompt }
        ],
        temperature: 0.7
      }
    )

    # Extract and parse the response
    content = response.dig("choices", 0, "message", "content")
    
    # Store the raw response for debugging and future reference
    response_data = {
      raw_content: content,
      perspective: perspective_key,
      role: perspective_data[:role]
    }
    
    # Parse the structured content
    parse_perspective_response(content, response_data)
  end

  def generate_system_prompt(role, focus)
    if @language == 'ro'
      <<~PROMPT
        Ești un analist de date și expert #{role} specializat în #{focus}.
        
        IMPORTANT: Returnează întotdeauna răspunsul în format JSON exact, fără nicio deviere.
        Fără preambul, fără explicații, fără comentarii.
        Răspunde strict în limba română și strict în formatul JSON specificat.
        
        Structura JSON exactă trebuie să fie:
        {
          "summary": "...",
          "insights": ["...", "...", "..."],
          "recommendations": ["...", "..."],
          "confidence_score": 1-10
        }
      PROMPT
    else
      <<~PROMPT
        You are a data analyst and expert #{role} focusing on #{focus}.
        
        IMPORTANT: Always return output in this exact JSON format, without any deviation.
        No preamble, no explanations, no commentary.
        Respond strictly in the specified JSON format.
        
        The exact JSON structure must be:
        {
          "summary": "...",
          "insights": ["...", "...", "..."],
          "recommendations": ["...", "..."],
          "confidence_score": 1-10
        }
      PROMPT
    end
  end

  def generate_perspective_prompt(role, focus)
    if @language == 'ro'
      <<~PROMPT
        Ca #{role} specializat în #{focus}, analizează aceste recenzii ale clienților. Răspunde strict în format JSON. Nu include explicații, titluri sau comentarii. Urmează exact această structură:

        {
          "summary": "...",
          "insights": ["...", "...", "..."],
          "recommendations": ["...", "..."],
          "confidence_score": 1-10
        }

        Recenzii:
        #{@reviews_text}
      PROMPT
    else
      <<~PROMPT
        As a #{role} focusing on #{focus}, analyze these customer reviews. Respond in strict JSON only. Do not include any explanations, headers, or commentary. Follow this structure exactly:

        {
          "summary": "...",
          "insights": ["...", "...", "..."],
          "recommendations": ["...", "..."],
          "confidence_score": 1-10
        }

        Reviews:
        #{@reviews_text}
      PROMPT
    end
  end

  def parse_perspective_response(content, response_data)
    begin
      # Clean up invalid JSON issues like trailing commas
      cleaned_content = content.gsub(/,\s*([}\]])/, '\1') # remove trailing commas before ] or }
      
      # Try to parse the cleaned response as JSON
      json_response = JSON.parse(cleaned_content)
      
      # Extract data from JSON response
      response_data[:summary] = json_response['summary'] if json_response['summary'].present?
      
      # Apply fuzzy deduplication to insights and recommendations
      if json_response['insights'].present?
        response_data[:insights] = fuzzy_deduplicate(json_response['insights'])
      end
      
      if json_response['recommendations'].present?
        response_data[:recommendations] = fuzzy_deduplicate(json_response['recommendations'])
      end
      
      response_data[:confidence_score] = json_response['confidence_score'] if json_response['confidence_score'].present?
    rescue JSON::ParserError
      # Fallback to the old parsing method if JSON parsing fails
      Rails.logger.error("Failed to parse JSON response: #{content}")
      
      # Simple parsing based on expected format
      sections = content.split(/\d+\.\s/).reject(&:blank?)
      
      response_data[:summary] = sections[0].strip if sections[0].present?
      
      if sections[1].present?
        insights = sections[1].strip.split(/•|-|\*/).map(&:strip).reject(&:blank?)
        response_data[:insights] = fuzzy_deduplicate(insights.take(3))
      end
      
      if sections[2].present?
        recommendations = sections[2].strip.split(/•|-|\*/).map(&:strip).reject(&:blank?)
        response_data[:recommendations] = fuzzy_deduplicate(recommendations.take(2))
      end
      
      # Extract confidence score if present
      if content.match(/confidence score.*(\d+)/i)
        response_data[:confidence_score] = content.match(/confidence score.*(\d+)/i)[1].to_i
      else
        response_data[:confidence_score] = 7 # Default confidence score
      end
    end
    
    response_data
  end

  # Fuzzy matcher for text similarity using embeddings
  def fuzzy_deduplicate(texts, threshold = 0.85)
    return [] if texts.blank?
    
    # Get embeddings for all texts
    embeddings = get_embeddings(texts)
    return texts if embeddings.nil? || embeddings.empty?
    
    # Track processed texts and results
    processed = Set.new
    results = []
    merged_groups = {}
    
    # Compare each text with all others using embeddings
    texts.each_with_index do |text, i|
      next if processed.include?(text)
      
      # Add this text to results and mark as processed
      results << text
      processed.add(text)
      merged_groups[text] = [text]
      
      # Find similar texts using embedding similarity
      texts.each_with_index do |other_text, j|
        next if text == other_text || processed.include?(other_text)
        
        # Calculate cosine similarity between embeddings
        similarity = calculate_embedding_similarity(embeddings[i], embeddings[j])
        
        # If similarity is above threshold, consider it a duplicate
        if similarity >= threshold
          processed.add(other_text)
          merged_groups[text] << other_text
        end
      end
    end
    
    # Store the merged groups for potential UI display
    @merged_insights = merged_groups if defined?(@merged_insights)
    
    results
  end
  
  # Get merged groups information
  def get_merged_groups
    @merged_insights || {}
  end
  
  # Get embeddings from OpenAI API
  def get_embeddings(texts)
    return [] if texts.blank?
    
    begin
      # Use the OpenAI client that's already initialized
      response = @client.embeddings(
        parameters: {
          model: "text-embedding-ada-002",
          input: texts
        }
      )
      
      # Extract embeddings from response
      embeddings = response.dig("data")&.map { |item| item["embedding"] }
      
      # Log success
      Rails.logger.info("Generated #{embeddings&.size} embeddings")
      
      return embeddings
    rescue => e
      # Log error and fall back to text-based similarity
      Rails.logger.error("Error generating embeddings: #{e.message}")
      return nil
    end
  end
  
  # Calculate cosine similarity between two embedding vectors
  def calculate_embedding_similarity(vec1, vec2)
    return 0 unless vec1 && vec2 && vec1.size == vec2.size
    
    # Convert arrays to Vector objects
    v1 = Vector.elements(vec1)
    v2 = Vector.elements(vec2)
    
    # Calculate cosine similarity: dot(v1, v2) / (|v1| * |v2|)
    dot_product = v1.inner_product(v2)
    magnitude1 = Math.sqrt(v1.inner_product(v1))
    magnitude2 = Math.sqrt(v2.inner_product(v2))
    
    return 0 if magnitude1 == 0 || magnitude2 == 0
    dot_product / (magnitude1 * magnitude2)
  end
  
  # Calculate text similarity using a combination of methods
  def calculate_similarity(text1, text2)
    # Normalize texts for comparison
    t1 = text1.downcase.gsub(/[^a-z0-9\s]/, '')
    t2 = text2.downcase.gsub(/[^a-z0-9\s]/, '')
    
    # Get words from both texts (not unique - we want to consider all words)
    words1 = t1.split
    words2 = t2.split
    
    # Calculate word overlap
    common_words = (words1 & words2).size
    total_words = [words1.size, words2.size].max
    word_overlap_ratio = total_words == 0 ? 0 : common_words.to_f / total_words
    
    # Calculate key verb and noun overlap (more important for meaning)
    key_words1 = extract_key_words(t1)
    key_words2 = extract_key_words(t2)
    key_overlap = (key_words1 & key_words2).size
    total_key_words = [key_words1.size, key_words2.size].max
    key_overlap_ratio = total_key_words == 0 ? 0 : key_overlap.to_f / total_key_words
    
    # Calculate substring similarity
    substring_similarity = calculate_substring_similarity(t1, t2)
    
    # Weighted average of different similarity measures
    # Give more weight to key word overlap as it's more important for semantic similarity
    (word_overlap_ratio * 0.3) + (key_overlap_ratio * 0.5) + (substring_similarity * 0.2)
  end
  
  # Extract key words (verbs and nouns) that carry most of the meaning
  def extract_key_words(text)
    # Common stop words to filter out
    stop_words = %w(the a an and or but to in on at for with by of from as)
    
    # Split text into words and filter out stop words
    words = text.split.reject { |word| stop_words.include?(word) || word.length < 3 }
    
    # Return the filtered words
    words
  end
  
  # Calculate similarity based on common substrings
  def calculate_substring_similarity(text1, text2)
    # Find the longest common substring
    shorter = [text1.length, text2.length].min
    max_length = 0
    
    # Try different substring lengths
    (3..shorter).each do |len|
      text1.chars.each_cons(len) do |substring|
        substr = substring.join
        if text2.include?(substr) && substr.length > max_length
          max_length = substr.length
        end
      end
    end
    
    # Return ratio of longest common substring to shorter text length
    shorter == 0 ? 0 : max_length.to_f / shorter
  end
  
  # Categorize insights by theme
  def categorize_insights(insights)
    # Define common themes and their related keywords
    themes = {
      'service' => ['service', 'staff', 'employee', 'attentive', 'friendly', 'helpful', 'rude', 'responsive'],
      'quality' => ['quality', 'product', 'food', 'item', 'consistency', 'standard'],
      'experience' => ['experience', 'atmosphere', 'ambiance', 'environment', 'feel', 'impression'],
      'value' => ['price', 'value', 'cost', 'expensive', 'affordable', 'worth', 'overpriced'],
      'operations' => ['wait', 'time', 'delay', 'slow', 'quick', 'fast', 'efficient', 'process']
    }
    
    # Initialize result hash
    categorized = {}
    themes.keys.each { |theme| categorized[theme] = [] }
    categorized['other'] = [] # For uncategorized insights
    
    # Categorize each insight
    insights.each do |insight|
      insight_text = insight.downcase
      
      # Check which theme has the most keyword matches
      best_match = nil
      best_count = 0
      
      themes.each do |theme, keywords|
        count = keywords.count { |keyword| insight_text.include?(keyword) }
        if count > best_count
          best_count = count
          best_match = theme
        end
      end
      
      # Add to appropriate category
      if best_count > 0
        categorized[best_match] << insight
      else
        categorized['other'] << insight
      end
    end
    
    # Remove empty categories
    categorized.delete_if { |_, insights| insights.empty? }
    
    categorized
  end
  
  # Sort recommendations by priority/impact
  def prioritize_recommendations(recommendations)
    # Keywords indicating high priority
    high_priority = ['critical', 'urgent', 'immediately', 'significant', 'major', 'important']
    medium_priority = ['should', 'consider', 'improve', 'enhance', 'address']
    
    # Score each recommendation
    scored_recs = recommendations.map do |rec|
      rec_text = rec.downcase
      
      # Calculate priority score
      score = 0
      score += 10 if high_priority.any? { |word| rec_text.include?(word) }
      score += 5 if medium_priority.any? { |word| rec_text.include?(word) }
      
      # Add points for mentions of customer satisfaction
      score += 3 if rec_text.include?('customer') || rec_text.include?('satisfaction')
      
      # Add points for mentions of quality
      score += 2 if rec_text.include?('quality')
      
      [rec, score]
    end
    
    # Sort by score (descending)
    scored_recs.sort_by { |_, score| -score }.map(&:first)
  end

  def synthesize_perspectives
    # Prepare the synthesis prompt with all perspective results
    synthesis_prompt = generate_synthesis_prompt
    
    # Make the final API call for synthesis
    response = @client.chat(
      parameters: {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: generate_synthesis_system_prompt },
          { role: "user", content: synthesis_prompt }
        ],
        temperature: 0.3 # Lower temperature for more consistent JSON formatting
      }
    )
    
    # Parse the JSON response
    content = response.dig("choices", 0, "message", "content")
    begin
      # Clean up invalid JSON issues like trailing commas
      cleaned_content = content.gsub(/,\s*([}\]])/, '\1') # remove trailing commas before ] or }
      
      parsed_response = JSON.parse(cleaned_content)
      
      # Initialize storage for merged groups
      @merged_insights = {}
      @merged_recommendations = {}
      
      # Apply fuzzy deduplication to recommendations and insights
      if parsed_response['recommendations'].present?
        # Deduplicate recommendations using embedding-based similarity
        deduped_recommendations = fuzzy_deduplicate(parsed_response['recommendations'])
        
        # Store merged recommendation groups
        @merged_recommendations = get_merged_groups.clone
        
        # Prioritize and cap recommendations at 3
        parsed_response['recommendations'] = prioritize_recommendations(deduped_recommendations).take(3)
        
        # Add merged groups to the response for UI display
        parsed_response['merged_recommendations'] = {}
        parsed_response['recommendations'].each do |rec|
          if @merged_recommendations[rec] && @merged_recommendations[rec].size > 1
            parsed_response['merged_recommendations'][rec] = @merged_recommendations[rec].reject { |r| r == rec }
          end
        end
      end
      
      if parsed_response['key_insights'].present?
        # Reset merged insights for this operation
        @merged_insights = {}
        
        # Deduplicate insights using embedding-based similarity
        deduped_insights = fuzzy_deduplicate(parsed_response['key_insights'])
        
        # Store the merged insight groups
        merged_insights_groups = get_merged_groups.clone
        
        # Categorize insights by theme
        parsed_response['categorized_insights'] = categorize_insights(deduped_insights)
        
        # Use deduplicated insights in the response
        parsed_response['key_insights'] = deduped_insights
        
        # Add merged groups to the response for UI display
        parsed_response['merged_insights'] = {}
        parsed_response['key_insights'].each do |insight|
          if merged_insights_groups[insight] && merged_insights_groups[insight].size > 1
            parsed_response['merged_insights'][insight] = merged_insights_groups[insight].reject { |i| i == insight }
          end
        end
      end
      
      # Add derived sentiment confidence based on perspective confidence scores
      if parsed_response['sentiment'].present?
        # Calculate average confidence score from all perspectives
        avg_confidence = [
          @perspective_results[:customer_experience][:confidence_score].to_f,
          @perspective_results[:operational_efficiency][:confidence_score].to_f,
          @perspective_results[:market_positioning][:confidence_score].to_f
        ].sum / 3.0
        
        # Add sentiment confidence metadata
        parsed_response['sentiment_confidence'] = avg_confidence.round(1)
        
        # Verify sentiment matches confidence pattern
        # High confidence (>7) should typically be definitive (positive/negative)
        # Medium confidence (4-6) often neutral
        # This is just a sanity check, not overriding the AI's sentiment
        if avg_confidence > 7.0 && parsed_response['sentiment'] == 'neutral'
          Rails.logger.info("High confidence score (#{avg_confidence}) with neutral sentiment - unusual pattern")
        end
      end
      
      response["parsed_json"] = parsed_response
    rescue JSON::ParserError => e
      Rails.logger.error("Failed to parse synthesis JSON response: #{e.message}")
    end
    
    # Return the response with parsed JSON if available
    response
  end

  def generate_synthesis_system_prompt
    if @language == 'ro'
      <<~PROMPT
        Ești un analist de date și expert în afaceri care sintetizează multiple perspective în recomandări acționabile.
        
        IMPORTANT: Returnează întotdeauna răspunsul în format JSON exact, fără nicio deviere.
        Fără preambul, fără explicații, fără comentarii.
        Răspunde strict în limba română și strict în formatul JSON specificat.
        
        Structura JSON exactă trebuie să fie:
        {
          "summary": "...",
          "key_insights": ["...", "...", "...", "...", "..."],
          "recommendations": ["...", "...", "..."],
          "sentiment": "pozitiv|neutru|negativ"
        }
      PROMPT
    else
      <<~PROMPT
        You are a data analyst and business expert who synthesizes multiple perspectives into actionable insights.
        
        IMPORTANT: Always return output in this exact JSON format, without any deviation.
        No preamble, no explanations, no commentary.
        Respond strictly in the specified JSON format.
        
        The exact JSON structure must be:
        {
          "summary": "...",
          "key_insights": ["...", "...", "...", "...", "..."],
          "recommendations": ["...", "...", "..."],
          "sentiment": "positive|neutral|negative"
        }
      PROMPT
    end
  end

  def generate_synthesis_prompt
    if @language == 'ro'
      prompt = <<~PROMPT
        Am analizat recenziile clienților din trei perspective diferite. Te rog să sintetizezi aceste perspective într-o analiză comprehensivă.
        
        PERSPECTIVA EXPERIENȚEI CLIENTULUI:
        #{@perspective_results[:customer_experience].to_json}
        
        PERSPECTIVA EFICIENȚEI OPERAȚIONALE:
        #{@perspective_results[:operational_efficiency].to_json}
        
        PERSPECTIVA POZIȚIONĂRII PE PIAȚĂ:
        #{@perspective_results[:market_positioning].to_json}
        
        Pe baza acestor perspective, răspunde strict în format JSON. Nu include explicații, titluri sau comentarii. Urmează exact această structură:

        {
          "summary": "...",
          "key_insights": ["...", "...", "...", "...", "..."],
          "recommendations": ["...", "...", "..."],
          "sentiment": "pozitiv|neutru|negativ"
        }
        
        IMPORTANT: Asigură-te că nu există recomandări sau observații duplicate. Fiecare recomandare și observație trebuie să fie unică și distinctă. Evită virgulele finale în array-uri JSON.
      PROMPT
    else
      prompt = <<~PROMPT
        I have analyzed customer reviews from three different perspectives. Please synthesize these perspectives into a comprehensive analysis.
        
        CUSTOMER EXPERIENCE PERSPECTIVE:
        #{@perspective_results[:customer_experience].to_json}
        
        OPERATIONAL EFFICIENCY PERSPECTIVE:
        #{@perspective_results[:operational_efficiency].to_json}
        
        MARKET POSITIONING PERSPECTIVE:
        #{@perspective_results[:market_positioning].to_json}
        
        Based on these perspectives, respond in strict JSON only. Do not include any explanations, headers, or commentary. Follow this structure exactly:

        {
          "summary": "...",
          "key_insights": ["...", "...", "...", "...", "..."],
          "recommendations": ["...", "...", "..."],
          "sentiment": "positive|neutral|negative"
        }
        
        IMPORTANT: Ensure there are no duplicate recommendations or insights. Each recommendation and insight must be unique and distinct. Avoid trailing commas in JSON arrays.
      PROMPT
    end
  end
end
