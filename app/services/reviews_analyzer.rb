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
      "Ești un expert #{role} specializat în #{focus}. Răspunde în limba română."
    else
      "You are an expert #{role} focusing on #{focus}."
    end
  end

  def generate_perspective_prompt(role, focus)
    if @language == 'ro'
      <<~PROMPT
        Ca #{role} specializat în #{focus}, analizează aceste recenzii ale clienților și oferă:
        
        1. Un rezumat scurt (2-3 propoziții) din perspectiva ta specifică
        2. Trei observații cheie legate de domeniul tău de expertiză
        3. Două recomandări specifice și aplicabile bazate pe analiza ta
        4. Un scor de încredere (1-10) pentru recomandările tale
        
        Formatează răspunsul tău în secțiuni clare cu titluri pentru fiecare parte.
        
        Recenzii:
        #{@reviews_text}
      PROMPT
    else
      <<~PROMPT
        As a #{role} focusing on #{focus}, analyze these customer reviews and provide:
        
        1. A brief summary (2-3 sentences) from your specific perspective
        2. Three key insights related to your area of expertise
        3. Two specific, actionable recommendations based on your analysis
        4. A confidence score (1-10) for your recommendations
        
        Format your response in clear sections with headings for each part.
        
        Reviews:
        #{@reviews_text}
      PROMPT
    end
  end

  def parse_perspective_response(content, response_data)
    # Simple parsing based on expected format
    sections = content.split(/\d+\.\s/).reject(&:blank?)
    
    response_data[:summary] = sections[0].strip if sections[0].present?
    
    if sections[1].present?
      insights = sections[1].strip.split(/•|-|\*/).map(&:strip).reject(&:blank?)
      response_data[:insights] = insights.take(3)
    end
    
    if sections[2].present?
      recommendations = sections[2].strip.split(/•|-|\*/).map(&:strip).reject(&:blank?)
      response_data[:recommendations] = recommendations.take(2)
    end
    
    # Extract confidence score if present
    if content.match(/confidence score.*(\d+)/i)
      response_data[:confidence_score] = content.match(/confidence score.*(\d+)/i)[1].to_i
    else
      response_data[:confidence_score] = 7 # Default confidence score
    end
    
    response_data
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
        temperature: 0.7
      }
    )
    
    # Return just the response to maintain compatibility with the existing model
    # The multi-perspective analysis happens internally but doesn't change the output format
    response
  end

  def generate_synthesis_system_prompt
    if @language == 'ro'
      "Ești un analist de afaceri expert care sintetizează multiple perspective în recomandări acționabile. Răspunde în limba română."
    else
      "You are an expert business analyst who synthesizes multiple perspectives into actionable insights."
    end
  end

  def generate_synthesis_prompt
    if @language == 'ro'
      perspective_labels = {
        customer_experience: "PERSPECTIVA EXPERIENȚEI CLIENTULUI",
        operational_efficiency: "PERSPECTIVA EFICIENȚEI OPERAȚIONALE",
        market_positioning: "PERSPECTIVA POZIȚIONĂRII PE PIAȚĂ"
      }
      
      summary_label = "Rezumat"
      insights_label = "Observații Cheie"
      recommendations_label = "Recomandări"
      confidence_label = "Nivel de încredere"
      
      prompt = <<~PROMPT
        Am analizat recenziile clienților din trei perspective diferite. Te rog să sintetizezi aceste perspective într-o analiză comprehensivă.
        
        #{perspective_labels[:customer_experience]}:
        #{summary_label}: #{@perspective_results[:customer_experience][:summary]}
        #{insights_label}: #{@perspective_results[:customer_experience][:insights].join(" | ")}
        #{recommendations_label}: #{@perspective_results[:customer_experience][:recommendations].join(" | ")}
        #{confidence_label}: #{@perspective_results[:customer_experience][:confidence_score]}/10
        
        #{perspective_labels[:operational_efficiency]}:
        #{summary_label}: #{@perspective_results[:operational_efficiency][:summary]}
        #{insights_label}: #{@perspective_results[:operational_efficiency][:insights].join(" | ")}
        #{recommendations_label}: #{@perspective_results[:operational_efficiency][:recommendations].join(" | ")}
        #{confidence_label}: #{@perspective_results[:operational_efficiency][:confidence_score]}/10
        
        #{perspective_labels[:market_positioning]}:
        #{summary_label}: #{@perspective_results[:market_positioning][:summary]}
        #{insights_label}: #{@perspective_results[:market_positioning][:insights].join(" | ")}
        #{recommendations_label}: #{@perspective_results[:market_positioning][:recommendations].join(" | ")}
        #{confidence_label}: #{@perspective_results[:market_positioning][:confidence_score]}/10
        
        Pe baza acestor perspective, te rog să oferi:
        1. Un rezumat scurt de 2-3 propoziții care să reprezinte rezumatul general al recenziilor
        2. Cinci puncte cheie de observații care să incorporeze toate perspectivele
        3. Trei recomandări specifice pentru companie bazate pe aceste observații, prioritizate după importanță
        4. Sentimentul general (pozitiv, negativ sau neutru)
        
        Formatează răspunsul tău exact în această structură:
        
        1. [Rezumatul tău aici]
        
        2. * [Prima observație]
           * [A doua observație]
           * [A treia observație]
           * [A patra observație]
           * [A cincea observație]
        
        3. * [Prima recomandare]
           * [A doua recomandare]
           * [A treia recomandare]
        
        4. [Analiza ta de sentiment: pozitiv, negativ sau neutru]
      PROMPT
    else
      prompt = <<~PROMPT
        I have analyzed customer reviews from three different perspectives. Please synthesize these perspectives into a comprehensive analysis.
        
        CUSTOMER EXPERIENCE PERSPECTIVE:
        Summary: #{@perspective_results[:customer_experience][:summary]}
        Key Insights: #{@perspective_results[:customer_experience][:insights].join(" | ")}
        Recommendations: #{@perspective_results[:customer_experience][:recommendations].join(" | ")}
        Confidence: #{@perspective_results[:customer_experience][:confidence_score]}/10
        
        OPERATIONAL EFFICIENCY PERSPECTIVE:
        Summary: #{@perspective_results[:operational_efficiency][:summary]}
        Key Insights: #{@perspective_results[:operational_efficiency][:insights].join(" | ")}
        Recommendations: #{@perspective_results[:operational_efficiency][:recommendations].join(" | ")}
        Confidence: #{@perspective_results[:operational_efficiency][:confidence_score]}/10
        
        MARKET POSITIONING PERSPECTIVE:
        Summary: #{@perspective_results[:market_positioning][:summary]}
        Key Insights: #{@perspective_results[:market_positioning][:insights].join(" | ")}
        Recommendations: #{@perspective_results[:market_positioning][:recommendations].join(" | ")}
        Confidence: #{@perspective_results[:market_positioning][:confidence_score]}/10
        
        Based on these perspectives, please provide:
        1. A brief 2-3 sentences that should be the overall summary of the reviews
        2. Five bullet points of key insights that incorporate all perspectives
        3. Three specific recommendations for the company based on these insights, prioritized by importance
        4. The overall sentiment (positive, negative, or neutral)
        
        Format your response in exactly this structure:
        
        1. [Your summary here]
        
        2. * [First insight]
           * [Second insight]
           * [Third insight]
           * [Fourth insight]
           * [Fifth insight]
        
        3. * [First recommendation]
           * [Second recommendation]
           * [Third recommendation]
        
        4. [Your sentiment analysis: positive, negative, or neutral]
      PROMPT
    end
  end
end
