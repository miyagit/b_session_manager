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

ActiveRecord::Schema[8.1].define(version: 2026_11_03_003055) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "admin_users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
  end

  create_table "line_message_deliveries", force: :cascade do |t|
    t.bigint "report_id", null: false
    t.string "status", default: "pending", null: false
    t.string "message_id"
    t.text "error_message"
    t.datetime "sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["report_id"], name: "index_line_message_deliveries_on_report_id", unique: true
  end

  create_table "report_results", force: :cascade do |t|
    t.bigint "report_id", null: false
    t.bigint "work_assignment_id", null: false
    t.integer "acquired_count", null: false
    t.integer "approach_count"
    t.integer "card_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["report_id", "work_assignment_id"], name: "index_report_results_on_report_id_and_work_assignment_id", unique: true
    t.index ["report_id"], name: "index_report_results_on_report_id"
    t.index ["work_assignment_id"], name: "index_report_results_on_work_assignment_id"
    t.check_constraint "acquired_count >= 0", name: "report_results_acquired_count_non_negative"
    t.check_constraint "approach_count >= 0", name: "report_results_approach_count_non_negative"
    t.check_constraint "card_count >= 0", name: "report_results_card_count_non_negative"
  end

  create_table "reports", force: :cascade do |t|
    t.bigint "work_session_id", null: false
    t.bigint "submitted_by_id", null: false
    t.string "report_type", null: false
    t.integer "report_slot", null: false
    t.datetime "reported_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["submitted_by_id"], name: "index_reports_on_submitted_by_id"
    t.index ["work_session_id", "report_slot"], name: "index_reports_on_work_session_id_and_report_slot", unique: true
    t.index ["work_session_id"], name: "index_reports_on_work_session_id"
    t.check_constraint "report_slot = ANY (ARRAY[13, 16, 19, 22])", name: "reports_report_slot_fixed_times"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "line_uid"
    t.integer "role", default: 0, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_uid"], name: "index_users_on_line_uid", unique: true
  end

  create_table "work_assignments", force: :cascade do |t|
    t.bigint "work_session_id", null: false
    t.bigint "user_id", null: false
    t.integer "target_count", null: false
    t.integer "status", default: 0, null: false
    t.datetime "confirmed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_work_assignments_on_user_id"
    t.index ["work_session_id", "user_id"], name: "index_work_assignments_on_work_session_id_and_user_id", unique: true
    t.index ["work_session_id"], name: "index_work_assignments_on_work_session_id"
    t.check_constraint "target_count >= 0", name: "work_assignments_target_count_non_negative"
  end

  create_table "work_locations", force: :cascade do |t|
    t.string "name", null: false
    t.string "category", null: false
    t.integer "budget_count"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_work_locations_on_name", unique: true
  end

  create_table "work_sessions", force: :cascade do |t|
    t.bigint "work_location_id", null: false
    t.date "work_date", null: false
    t.string "team_name"
    t.integer "budget_count"
    t.string "line_group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["work_date"], name: "index_work_sessions_on_work_date"
    t.index ["work_location_id"], name: "index_work_sessions_on_work_location_id"
    t.check_constraint "budget_count >= 0", name: "work_sessions_budget_count_non_negative"
  end

  add_foreign_key "line_message_deliveries", "reports"
  add_foreign_key "report_results", "reports"
  add_foreign_key "report_results", "work_assignments"
  add_foreign_key "reports", "users", column: "submitted_by_id"
  add_foreign_key "reports", "work_sessions"
  add_foreign_key "work_assignments", "users"
  add_foreign_key "work_assignments", "work_sessions"
  add_foreign_key "work_sessions", "work_locations"
end
