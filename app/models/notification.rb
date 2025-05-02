class Notification < ApplicationRecord
  belongs_to :recipient, polymorphic: true
  
  # Removed ActionCable broadcasting
  
  # Handle data as JSON
  def data
    super.present? ? JSON.parse(super) : {}
  rescue JSON::ParserError
    {}
  end
  
  def data=(value)
    super(value.to_json)
  end
  
  # Scopes
  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc).limit(5) }
  
  # Mark notification as read
  def mark_as_read!
    update(read_at: Time.current)
  end
  
  # Check if notification is read
  def read?
    read_at.present?
  end
  
  # Get notification title based on action
  def notification_title
    case action
    when "negative_review"
      "⚠️ Negative Review Alert"
    when "new_review"
      "New Review Received"
    else
      "New Notification"
    end
  end
  
  # Get notification body based on action
  def notification_body
    case action
    when "negative_review", "new_review"
      "#{data_hash['rating']}-star review: #{data_hash['content_preview']}"
    else
      "You have a new notification"
    end
  end
  
  # Helper to get data safely
  def data_hash
    data
  end
  
end
