require "test_helper"

class CompanyReviewsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get company_reviews_new_url
    assert_response :success
  end

  test "should get create" do
    get company_reviews_create_url
    assert_response :success
  end

  test "should get show" do
    get company_reviews_show_url
    assert_response :success
  end
end
