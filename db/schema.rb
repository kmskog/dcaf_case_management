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

ActiveRecord::Schema[7.2].define(version: 2025_03_03_024816) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "archived_patients", force: :cascade do |t|
    t.string "identifier"
    t.string "age_range", default: "not_specified"
    t.boolean "has_alt_contact"
    t.string "voicemail_preference", default: "not_specified"
    t.string "line_legacy"
    t.string "language"
    t.date "intake_date"
    t.boolean "shared_flag"
    t.string "city"
    t.string "state"
    t.string "county"
    t.string "race_ethnicity"
    t.string "employment_status"
    t.string "insurance"
    t.string "income"
    t.integer "notes_count"
    t.boolean "has_special_circumstances"
    t.string "referred_by"
    t.boolean "referred_to_clinic"
    t.date "procedure_date"
    t.boolean "textable"
    t.bigint "clinic_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "fund_id"
    t.string "procedure_type"
    t.boolean "multiday_appointment"
    t.boolean "practical_support_waiver", comment: "Optional practical support services waiver, for funds that use them"
    t.bigint "region_id", null: false
    t.index ["clinic_id"], name: "index_archived_patients_on_clinic_id"
    t.index ["fund_id"], name: "index_archived_patients_on_fund_id"
    t.index ["line_legacy"], name: "index_archived_patients_on_line_legacy"
    t.index ["region_id"], name: "index_archived_patients_on_region_id"
  end

  create_table "auth_factors", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.string "channel"
    t.boolean "enabled", default: false
    t.boolean "registration_complete", default: false
    t.string "external_id"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "user_id"], name: "index_auth_factors_on_name_and_user_id", unique: true
    t.index ["user_id"], name: "index_auth_factors_on_user_id"
  end

  create_table "call_list_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "patient_id", null: false
    t.string "line_legacy"
    t.integer "order_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "fund_id"
    t.bigint "region_id", null: false
    t.index ["fund_id"], name: "index_call_list_entries_on_fund_id"
    t.index ["line_legacy"], name: "index_call_list_entries_on_line_legacy"
    t.index ["patient_id", "user_id", "fund_id"], name: "index_call_list_entries_on_patient_id_and_user_id_and_fund_id", unique: true
    t.index ["patient_id"], name: "index_call_list_entries_on_patient_id"
    t.index ["region_id"], name: "index_call_list_entries_on_region_id"
    t.index ["user_id"], name: "index_call_list_entries_on_user_id"
  end

  create_table "calls", force: :cascade do |t|
    t.integer "status", null: false
    t.string "can_call_type", null: false
    t.bigint "can_call_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "fund_id"
    t.index ["can_call_type", "can_call_id"], name: "index_calls_on_can_call_type_and_can_call_id"
    t.index ["fund_id"], name: "index_calls_on_fund_id"
  end

  create_table "clinics", force: :cascade do |t|
    t.string "name", null: false
    t.string "street_address"
    t.string "city"
    t.string "state"
    t.string "zip"
    t.string "phone"
    t.string "fax"
    t.boolean "active", default: true, null: false
    t.boolean "accepts_medicaid"
    t.decimal "coordinates", array: true
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "fund_id"
    t.index ["fund_id"], name: "index_clinics_on_fund_id"
    t.index ["name", "fund_id"], name: "index_clinics_on_name_and_fund_id", unique: true
  end

  create_table "configs", force: :cascade do |t|
    t.integer "config_key", null: false
    t.jsonb "config_value", default: {"options"=>[]}, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "fund_id"
    t.index ["config_key", "fund_id"], name: "index_configs_on_config_key_and_fund_id", unique: true
    t.index ["fund_id"], name: "index_configs_on_fund_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "cm_name"
    t.integer "event_type"
    t.string "line_legacy"
    t.string "patient_name"
    t.string "patient_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "fund_id"
    t.bigint "region_id", null: false
    t.index ["created_at"], name: "index_events_on_created_at"
    t.index ["fund_id"], name: "index_events_on_fund_id"
    t.index ["line_legacy"], name: "index_events_on_line_legacy"
    t.index ["region_id"], name: "index_events_on_region_id"
  end

  create_table "fulfillments", force: :cascade do |t|
    t.boolean "fulfilled", default: false, null: false
    t.date "procedure_date"
    t.boolean "audited"
    t.string "can_fulfill_type", null: false
    t.bigint "can_fulfill_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "fund_id"
    t.index ["audited"], name: "index_fulfillments_on_audited"
    t.index ["can_fulfill_type", "can_fulfill_id"], name: "index_fulfillments_on_can_fulfill_type_and_can_fulfill_id"
    t.index ["fulfilled"], name: "index_fulfillments_on_fulfilled"
    t.index ["fund_id"], name: "index_fulfillments_on_fund_id"
  end

  create_table "funds", force: :cascade do |t|
    t.string "name"
    t.string "subdomain"
    t.string "domain"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "full_name", comment: "Full name of the fund. e.g. DC Abortion Fund"
    t.string "site_domain", comment: "URL of the fund's public-facing website. e.g. www.dcabortionfund.org"
    t.string "phone", comment: "Contact number for the abortion fund, usually the hotline"
  end

  create_table "notes", force: :cascade do |t|
    t.string "full_text", null: false
    t.bigint "patient_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "fund_id"
    t.string "can_note_type"
    t.bigint "can_note_id"
    t.index ["can_note_type", "can_note_id"], name: "index_notes_on_can_note"
    t.index ["fund_id"], name: "index_notes_on_fund_id"
    t.index ["patient_id"], name: "index_notes_on_patient_id"
  end

  create_table "old_passwords", force: :cascade do |t|
    t.string "encrypted_password", null: false
    t.string "password_archivable_type", null: false
    t.integer "password_archivable_id", null: false
    t.string "password_salt"
    t.datetime "created_at"
    t.index ["password_archivable_type", "password_archivable_id"], name: "index_password_archivable"
  end

  create_table "patients", force: :cascade do |t|
    t.string "name", null: false
    t.string "primary_phone", null: false
    t.string "emergency_contact"
    t.string "emergency_contact_phone"
    t.string "emergency_contact_relationship"
    t.string "identifier"
    t.string "voicemail_preference", default: "not_specified"
    t.string "line_legacy"
    t.string "language"
    t.string "pronouns"
    t.date "intake_date", null: false
    t.boolean "shared_flag"
    t.integer "age"
    t.string "city"
    t.string "state"
    t.string "county"
    t.string "zipcode"
    t.string "race_ethnicity"
    t.string "employment_status"
    t.integer "household_size_children"
    t.integer "household_size_adults"
    t.string "insurance"
    t.string "income"
    t.string "special_circumstances", default: [], array: true
    t.string "referred_by"
    t.boolean "referred_to_clinic"
    t.date "procedure_date"
    t.boolean "textable"
    t.bigint "clinic_id"
    t.bigint "last_edited_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "fund_id"
    t.string "procedure_type"
    t.time "appointment_time", comment: "A patient's appointment time"
    t.boolean "multiday_appointment"
    t.boolean "practical_support_waiver", comment: "Optional practical support services waiver, for funds that use them"
    t.string "legal_name"
    t.string "email"
    t.string "emergency_reference_wording"
    t.string "in_case_of_emergency", default: [], array: true
    t.bigint "region_id", null: false
    t.index ["clinic_id"], name: "index_patients_on_clinic_id"
    t.index ["emergency_contact"], name: "index_patients_on_emergency_contact"
    t.index ["emergency_contact_phone"], name: "index_patients_on_emergency_contact_phone"
    t.index ["fund_id"], name: "index_patients_on_fund_id"
    t.index ["identifier"], name: "index_patients_on_identifier"
    t.index ["last_edited_by_id"], name: "index_patients_on_last_edited_by_id"
    t.index ["line_legacy"], name: "index_patients_on_line_legacy"
    t.index ["name"], name: "index_patients_on_name"
    t.index ["primary_phone", "fund_id"], name: "index_patients_on_primary_phone_and_fund_id", unique: true
    t.index ["region_id"], name: "index_patients_on_region_id"
    t.index ["shared_flag"], name: "index_patients_on_shared_flag"
  end

  create_table "pledge_configs", force: :cascade do |t|
    t.string "contact_email"
    t.string "billing_email"
    t.string "phone"
    t.string "logo_url"
    t.integer "logo_height"
    t.integer "logo_width"
    t.string "address1"
    t.string "address2"
    t.bigint "fund_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "remote_pledge", comment: "Whether to use the remote pledge generation service"
    t.json "remote_pledge_extras", default: {}, comment: "Extra fields required for remote pledge generation. Key should be the field, and value should be whether or not it is required."
    t.index ["fund_id"], name: "index_pledge_configs_on_fund_id"
  end

  create_table "practical_supports", force: :cascade do |t|
    t.string "support_type", null: false
    t.boolean "confirmed"
    t.string "source", null: false
    t.string "can_support_type"
    t.bigint "can_support_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "fund_id"
    t.decimal "amount", precision: 8, scale: 2
    t.string "attachment_url", comment: "A link to a fund's stored receipt for this particular entry"
    t.boolean "fulfilled", comment: "An indicator that a particular practical support is fulfilled, completed, or paid out."
    t.date "purchase_date", comment: "Date of purchase, if applicable"
    t.datetime "start_time"
    t.datetime "end_time"
    t.index ["can_support_type", "can_support_id"], name: "index_practical_supports_on_can_support_type_and_can_support_id"
    t.index ["fund_id"], name: "index_practical_supports_on_fund_id"
  end

  create_table "regions", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "fund_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "state"
    t.index ["fund_id"], name: "index_regions_on_fund_id"
    t.index ["name", "fund_id"], name: "index_regions_on_name_and_fund_id", unique: true
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "region"
    t.integer "role", default: 0, null: false
    t.boolean "disabled_by_fund", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at", precision: nil
    t.datetime "remember_created_at", precision: nil
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at", precision: nil
    t.datetime "last_sign_in_at", precision: nil
    t.inet "current_sign_in_ip"
    t.inet "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.datetime "locked_at", precision: nil
    t.bigint "fund_id"
    t.string "unique_session_id"
    t.string "session_validity_token"
    t.index ["email", "fund_id"], name: "index_users_on_email_and_fund_id", unique: true
    t.index ["fund_id"], name: "index_users_on_fund_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "versions", force: :cascade do |t|
    t.string "item_type"
    t.string "{:null=>false}"
    t.bigint "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.json "object"
    t.json "object_changes"
    t.datetime "created_at", precision: nil
    t.bigint "fund_id"
    t.index ["fund_id"], name: "index_versions_on_fund_id"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  add_foreign_key "archived_patients", "clinics"
  add_foreign_key "archived_patients", "funds"
  add_foreign_key "archived_patients", "regions"
  add_foreign_key "auth_factors", "users"
  add_foreign_key "call_list_entries", "funds"
  add_foreign_key "call_list_entries", "patients"
  add_foreign_key "call_list_entries", "regions"
  add_foreign_key "call_list_entries", "users"
  add_foreign_key "calls", "funds"
  add_foreign_key "clinics", "funds"
  add_foreign_key "configs", "funds"
  add_foreign_key "events", "funds"
  add_foreign_key "events", "regions"
  add_foreign_key "fulfillments", "funds"
  add_foreign_key "notes", "funds"
  add_foreign_key "patients", "clinics"
  add_foreign_key "patients", "funds"
  add_foreign_key "patients", "regions"
  add_foreign_key "patients", "users", column: "last_edited_by_id"
  add_foreign_key "practical_supports", "funds"
  add_foreign_key "regions", "funds"
  add_foreign_key "users", "funds"
  add_foreign_key "versions", "funds"
end
