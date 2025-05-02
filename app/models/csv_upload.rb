# == Schema Information
#
# Table name: csv_uploads
#
#  id         :integer          not null, primary key
#  name       :string
#  status     :string
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class CsvUpload < ApplicationRecord
  belongs_to :user
  has_one :analysis, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_one_attached :file
  
  validates :name, presence: true
  validates :file, presence: true
  
  # Status values
  STATUSES = {
    pending: 'pending',
    processing: 'processing',
    completed: 'completed',
    failed: 'failed'
  }
  
  validates :status, inclusion: { in: STATUSES.values }
  
  # Set default status to pending
  after_initialize :set_default_status, if: :new_record?
  
  private
  
  def set_default_status
    self.status ||= STATUSES[:pending]
  end
end
