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

ActiveRecord::Schema[7.1].define(version: 2026_02_16_082352) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "campaigns", force: :cascade do |t|
    t.string "name", null: false
    t.string "subject", null: false
    t.integer "status", default: 0, null: false
    t.bigint "email_template_id", null: false
    t.bigint "contact_list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.datetime "scheduled_at"
    t.index ["contact_list_id"], name: "index_campaigns_on_contact_list_id"
    t.index ["email_template_id"], name: "index_campaigns_on_email_template_id"
    t.index ["user_id"], name: "index_campaigns_on_user_id"
  end

  create_table "contact_list_memberships", force: :cascade do |t|
    t.bigint "contact_id", null: false
    t.bigint "contact_list_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_id"], name: "index_contact_list_memberships_on_contact_id"
    t.index ["contact_list_id"], name: "index_contact_list_memberships_on_contact_list_id"
  end

  create_table "contact_lists", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["name"], name: "index_contact_lists_on_name", unique: true
    t.index ["user_id"], name: "index_contact_lists_on_user_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.integer "status", default: 0, null: false
    t.jsonb "custom_attributes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id", "email"], name: "index_contacts_on_user_id_and_email", unique: true
    t.index ["user_id"], name: "index_contacts_on_user_id"
  end

  create_table "domains", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name"
    t.integer "status"
    t.text "dkim_private_key"
    t.text "dkim_public_key"
    t.string "dkim_selector"
    t.string "verification_error"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "verification_token"
    t.datetime "verification_sent_at"
    t.datetime "verified_at"
    t.integer "verification_attempts", default: 0, null: false
    t.index ["user_id"], name: "index_domains_on_user_id"
    t.index ["verification_token"], name: "index_domains_on_verification_token"
  end

  create_table "email_events", force: :cascade do |t|
    t.integer "event_type", null: false
    t.bigint "contact_id", null: false
    t.bigint "campaign_id"
    t.bigint "email_template_id"
    t.string "url"
    t.string "ip_address"
    t.text "user_agent"
    t.datetime "timestamp", default: -> { "now()" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "details"
    t.index ["campaign_id"], name: "index_email_events_on_campaign_id"
    t.index ["contact_id"], name: "index_email_events_on_contact_id"
    t.index ["email_template_id"], name: "index_email_events_on_email_template_id"
  end

  create_table "email_templates", force: :cascade do |t|
    t.string "name"
    t.string "subject"
    t.text "body"
    t.text "plain_text_body"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_email_templates_on_user_id"
  end

  create_table "senders", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "domain_id", null: false
    t.string "email"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["domain_id"], name: "index_senders_on_domain_id"
    t.index ["user_id"], name: "index_senders_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "password_digest", default: "", null: false
    t.string "api_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role"
    t.string "stripe_customer_id"
    t.string "stripe_subscription_id"
    t.index ["api_key"], name: "index_users_on_api_key", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "url", null: false
    t.jsonb "events", default: []
    t.boolean "active", default: true
    t.string "secret"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_webhook_endpoints_on_user_id"
  end

  add_foreign_key "campaigns", "contact_lists"
  add_foreign_key "campaigns", "email_templates"
  add_foreign_key "campaigns", "users"
  add_foreign_key "contact_list_memberships", "contact_lists"
  add_foreign_key "contact_list_memberships", "contacts"
  add_foreign_key "contact_lists", "users"
  add_foreign_key "contacts", "users"
  add_foreign_key "domains", "users"
  add_foreign_key "email_events", "campaigns"
  add_foreign_key "email_events", "contacts"
  add_foreign_key "email_events", "email_templates"
  add_foreign_key "email_templates", "users"
  add_foreign_key "senders", "domains"
  add_foreign_key "senders", "users"
  add_foreign_key "webhook_endpoints", "users"
end
