class CreateAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :analyses do |t|
      t.references :csv_upload, null: false, foreign_key: true
      t.string :sentiment
      t.text :summary
      t.text :insights
      t.integer :positive_count
      t.integer :negative_count
      t.integer :neutral_count

      t.timestamps
    end
  end
end
