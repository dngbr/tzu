class AddRecommendationsToAnalyses < ActiveRecord::Migration[8.0]
  def change
    add_column :analyses, :recommendations, :text
  end
end
