# == Schema Information
#
# Table name: reviews
#
#  id            :integer          not null, primary key
#  csv_upload_id :integer          not null
#  content       :text
#  sentiment     :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Review < ApplicationRecord
  belongs_to :csv_upload
  
  validates :content, presence: true
  validates :sentiment, presence: true
  
  # Sentiment values
  SENTIMENTS = {
    positive: 'positive',
    negative: 'negative',
    neutral: 'neutral'
  }
  
  validates :sentiment, inclusion: { in: SENTIMENTS.values }
  
  # Scopes for filtering by sentiment
  scope :positive, -> { where(sentiment: SENTIMENTS[:positive]) }
  scope :negative, -> { where(sentiment: SENTIMENTS[:negative]) }
  scope :neutral, -> { where(sentiment: SENTIMENTS[:neutral]) }
  
  # Helper method to get the user through the csv_upload association
  def user
    csv_upload.user
  end
end
