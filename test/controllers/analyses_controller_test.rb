require "test_helper"

class AnalysesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get analyses_show_url
    assert_response :success
  end
end
