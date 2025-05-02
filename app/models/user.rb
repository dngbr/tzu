# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  role                   :string
#  first_name             :string
#  last_name              :string
#

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         
  has_one :company, dependent: :destroy
  has_many :csv_uploads, dependent: :destroy
  has_many :notifications, as: :recipient, dependent: :destroy
  
  # Avatar attachment
  has_one_attached :avatar
  
  # Avatar validations
  validate :acceptable_avatar, if: -> { avatar.attached? }
  
  def acceptable_avatar
    # Validate content type
    unless avatar.content_type.in?(['image/png', 'image/jpeg', 'image/gif'])
      errors.add(:avatar, 'must be a PNG, JPEG, or GIF')
    end
    
    # Validate file size
    if avatar.byte_size > 5.megabytes
      errors.add(:avatar, 'must be less than 5MB')
    end
  end
  
  # Define roles
  ROLES = ['user', 'business_owner']
  
  # Validations
  validates :role, inclusion: { in: ROLES }, allow_nil: true
  
  # Helper methods
  def business_owner?
    role == 'business_owner'
  end
  
  def regular_user?
    role == 'user'
  end
end
