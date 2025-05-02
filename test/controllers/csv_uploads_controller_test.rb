require "test_helper"

class CsvUploadsControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get csv_uploads_new_url
    assert_response :success
  end

  test "should get create" do
    get csv_uploads_create_url
    assert_response :success
  end

  test "should get index" do
    get csv_uploads_index_url
    assert_response :success
  end

  test "should get show" do
    get csv_uploads_show_url
    assert_response :success
  end
end
