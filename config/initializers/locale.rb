# Set default and available locales
I18n.available_locales = [ :en, :ro ]
I18n.default_locale = :en

# Load translations from config/locales
Rails.application.config.i18n.load_path += Dir[Rails.root.join("config", "locales", "**", "*.{rb,yml}")]

# Enable locale fallbacks for I18n
Rails.application.config.i18n.fallbacks = true

# Set locale from params if available
Rails.application.config.middleware.use I18n::JS::Middleware if defined?(I18n::JS)
