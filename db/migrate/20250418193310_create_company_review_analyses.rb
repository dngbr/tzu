class CreateCompanyReviewAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :company_review_analyses do |t|
      t.references :company, null: false, foreign_key: true
      t.integer :reviews_count
      t.text :summary
      t.text :insights
      t.text :recommendations
      t.string :sentiment
      t.datetime :last_analyzed_at

      t.timestamps
    end
  end
end
