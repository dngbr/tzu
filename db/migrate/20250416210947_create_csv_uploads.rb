class CreateCsvUploads < ActiveRecord::Migration[8.0]
  def change
    create_table :csv_uploads do |t|
      t.string :name
      t.string :status
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
