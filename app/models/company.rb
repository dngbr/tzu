# == Schema Information
#
# Table name: companies
#
#  id          :integer          not null, primary key
#  name        :string
#  description :text
#  address     :string
#  phone       :string
#  website     :string
#  user_id     :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Company < ApplicationRecord
  belongs_to :user
  has_many :company_reviews, dependent: :destroy
  has_many :company_review_analyses, dependent: :destroy
  has_many :notifications, as: :recipient, dependent: :destroy
  
  # Attachments
  has_one_attached :brand_photo
  has_one_attached :background_photo
  
  # Validations
  validates :name, presence: true
  validates :description, presence: true
  validates :address, presence: true
  validates :phone, presence: true
  
  # Website is optional but should be a valid URL if provided
  validates :website, format: { with: URI::DEFAULT_PARSER.make_regexp, message: "must be a valid URL" },
                    allow_blank: true
                    
  # Ensure each user can only have one company
  validates :user_id, uniqueness: true
  
  # Language validation
  AVAILABLE_LANGUAGES = ['en', 'ro']
  validates :preferred_language, inclusion: { in: AVAILABLE_LANGUAGES }
  
  # Basic validations for brand photo
  validate :acceptable_brand_photo, if: -> { brand_photo.attached? }
  
  def acceptable_brand_photo
    # Validate content type
    unless brand_photo.content_type.in?(['image/png', 'image/jpeg', 'image/jpg'])
      errors.add(:brand_photo, 'must be a PNG or JPEG')
      return
    end
    
    # Validate file size
    if brand_photo.byte_size > 5.megabytes
      errors.add(:brand_photo, 'must be less than 5MB')
      return
    end
  end
  
  # Basic validations for background photo
  validate :acceptable_background_photo, if: -> { background_photo.attached? }
  
  def acceptable_background_photo
    # Validate content type
    unless background_photo.content_type.in?(['image/png', 'image/jpeg', 'image/jpg'])
      errors.add(:background_photo, 'must be a PNG or JPEG')
      return
    end
    
    # Validate file size
    if background_photo.byte_size > 10.megabytes
      errors.add(:background_photo, 'must be less than 10MB')
      return
    end
  end
  
  # Method to check if a new analysis can be triggered
  def can_trigger_new_analysis?
    company_reviews.unanalyzed.exists?
  end
  
  # Method to get unanalyzed reviews
  def unanalyzed_reviews
    company_reviews.unanalyzed
  end
end
