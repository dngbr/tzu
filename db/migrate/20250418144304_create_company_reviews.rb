class CreateCompanyReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :company_reviews do |t|
      t.references :company, null: false, foreign_key: true
      t.string :reviewer_name
      t.string :reviewer_phone
      t.text :content
      t.string :sentiment
      t.boolean :analyzed, default: false

      t.timestamps
    end
  end
end
