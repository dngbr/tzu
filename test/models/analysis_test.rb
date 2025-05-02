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

require "test_helper"

class AnalysisTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
