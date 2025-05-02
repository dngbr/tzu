class AddPreferredLanguageToCompanies < ActiveRecord::Migration[8.0]
  def change
    add_column :companies, :preferred_language, :string, default: 'en'
  end
end
