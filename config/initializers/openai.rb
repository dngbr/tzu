Rails.application.config.after_initialize do
  OpenAI.configure do |config|
    config.access_token = ENV['OPENAI_API_KEY']
  end
end