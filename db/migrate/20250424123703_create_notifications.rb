class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :recipient, polymorphic: true, null: false  # Company or User that receives the notification
      t.string :action                                         # Type of notification (e.g., "new_review", "negative_review")
      t.datetime :read_at                                      # When the notification was read (nil = unread)
      t.text :data                                             # JSON data with notification details

      t.timestamps
    end
    
    add_index :notifications, [:recipient_type, :recipient_id]
  end
end
