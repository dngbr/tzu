class CreateCompanies < ActiveRecord::Migration[8.0]
  def change
    create_table :companies do |t|
      t.string :name
      t.text :description
      t.string :address
      t.string :phone
      t.string :website
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
