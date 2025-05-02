# == Schema Information
#
# Table name: analyses
#
#  id              :integer          not null, primary key
#  csv_upload_id   :integer          not null
#  sentiment       :string
#  summary         :text
#  insights        :text
#  positive_count  :integer
#  negative_count  :integer
#  neutral_count   :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  recommendations :text
#

class Analysis < ApplicationRecord
  belongs_to :csv_upload
  
  validates :sentiment, presence: true, inclusion: { in: ['positive', 'negative', 'neutral'] }
  validates :summary, presence: true
  
  # Convert insights from string to array when reading from DB
  def insights
    return [] if self[:insights].blank?
    
    if self[:insights].is_a?(String)
      # Split by newlines or bullet points
      self[:insights].split(/\n|•/).map(&:strip).reject(&:blank?)
    else
      self[:insights]
    end
  end
  
  # Convert insights array to string when saving to DB
  def insights=(value)
    if value.is_a?(Array)
      self[:insights] = value.join("\n")
    else
      self[:insights] = value
    end
  end
  
  # Convert recommendations from string to array when reading from DB
  def recommendations
    return [] if self[:recommendations].blank?
    
    if self[:recommendations].is_a?(String)
      # Split by newlines or bullet points
      self[:recommendations].split(/\n|•/).map(&:strip).reject(&:blank?)
    else
      self[:recommendations]
    end
  end
  
  # Convert recommendations array to string when saving to DB
  def recommendations=(value)
    if value.is_a?(Array)
      self[:recommendations] = value.join("\n")
    else
      self[:recommendations] = value
    end
  end
  
  # Helper method to get the user through the csv_upload association
  def user
    csv_upload.user
  end
  
  # Calculate total number of reviews analyzed
  def total_reviews
    positive_count + negative_count + neutral_count
  end
  
  # Calculate percentage of positive reviews
  def positive_percentage
    return 0 if total_reviews.zero?
    ((positive_count.to_f / total_reviews) * 100).round
  end
  
  # Calculate percentage of negative reviews
  def negative_percentage
    return 0 if total_reviews.zero?
    ((negative_count.to_f / total_reviews) * 100).round
  end
  
  # Calculate percentage of neutral reviews
  def neutral_percentage
    return 0 if total_reviews.zero?
    ((neutral_count.to_f / total_reviews) * 100).round
  end
end
