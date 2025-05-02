# == Schema Information
#
# Table name: company_reviews
#
#  id             :integer          not null, primary key
#  company_id     :integer          not null
#  reviewer_name  :string
#  reviewer_phone :string
#  content        :text
#  sentiment      :string
#  analyzed       :boolean          default("0")
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require "test_helper"

class CompanyReviewTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
