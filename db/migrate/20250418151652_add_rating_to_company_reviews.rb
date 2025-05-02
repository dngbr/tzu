class AddRatingToCompanyReviews < ActiveRecord::Migration[8.0]
  def change
    add_column :company_reviews, :rating, :integer, default: 5
    add_check_constraint :company_reviews, "rating >= 1 AND rating <= 5", name: "check_rating_range"
  end
end
