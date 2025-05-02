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

require "test_helper"

class CsvUploadTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
