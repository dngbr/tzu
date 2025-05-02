# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_04_24_123703) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "analyses", force: :cascade do |t|
    t.integer "csv_upload_id", null: false
    t.string "sentiment"
    t.text "summary"
    t.text "insights"
    t.integer "positive_count"
    t.integer "negative_count"
    t.integer "neutral_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "recommendations"
    t.index ["csv_upload_id"], name: "index_analyses_on_csv_upload_id"
  end

  create_table "companies", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "address"
    t.string "phone"
    t.string "website"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "preferred_language", default: "en"
    t.index ["user_id"], name: "index_companies_on_user_id"
  end

  create_table "company_review_analyses", force: :cascade do |t|
    t.integer "company_id", null: false
    t.integer "reviews_count"
    t.text "summary"
    t.text "insights"
    t.text "recommendations"
    t.string "sentiment"
    t.datetime "last_analyzed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_company_review_analyses_on_company_id"
  end

  create_table "company_reviews", force: :cascade do |t|
    t.integer "company_id", null: false
    t.string "reviewer_name"
    t.string "reviewer_phone"
    t.text "content"
    t.string "sentiment"
    t.boolean "analyzed", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "rating", default: 5
    t.index ["company_id"], name: "index_company_reviews_on_company_id"
    t.check_constraint "rating >= 1 AND rating <= 5", name: "check_rating_range"
  end

  create_table "csv_uploads", force: :cascade do |t|
    t.string "name"
    t.string "status"
    t.integer "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_csv_uploads_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "recipient_type", null: false
    t.integer "recipient_id", null: false
    t.string "action"
    t.datetime "read_at"
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["recipient_type", "recipient_id"], name: "index_notifications_on_recipient"
    t.index ["recipient_type", "recipient_id"], name: "index_notifications_on_recipient_type_and_recipient_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "csv_upload_id", null: false
    t.text "content"
    t.string "sentiment"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["csv_upload_id"], name: "index_reviews_on_csv_upload_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role"
    t.string "first_name"
    t.string "last_name"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "analyses", "csv_uploads"
  add_foreign_key "companies", "users"
  add_foreign_key "company_review_analyses", "companies"
  add_foreign_key "company_reviews", "companies"
  add_foreign_key "csv_uploads", "users"
  add_foreign_key "reviews", "csv_uploads"
end
