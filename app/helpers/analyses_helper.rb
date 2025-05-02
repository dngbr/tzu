module AnalysesHelper
  # Translates text to the current locale if not English, otherwise returns original.
  # Replace the API endpoint and key with your chosen provider (e.g., Google, DeepL).
  def dynamic_translate(text)
    return text if I18n.locale == :en || text.blank?

    # Example: Google Translate API (pseudo-implementation)
    api_key = ENV['TRANSLATE_API_KEY']
    target_lang = I18n.locale.to_s

    response = Faraday.post("https://translation.googleapis.com/language/translate/v2", {
      q: text,
      target: target_lang,
      key: api_key
    })

    if response.success?
      json = JSON.parse(response.body)
      json.dig('data', 'translations', 0, 'translatedText') || text
    else
      text # fallback to original if translation fails
    end
  rescue => e
    Rails.logger.error("Translation failed: #{e.message}")
    text
  end
end
