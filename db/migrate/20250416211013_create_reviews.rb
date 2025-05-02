class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.references :csv_upload, null: false, foreign_key: true
      t.text :content
      t.string :sentiment

      t.timestamps
    end
  end
end
