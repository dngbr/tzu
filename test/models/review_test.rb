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

require "test_helper"

class ReviewTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
