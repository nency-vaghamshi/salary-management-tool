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

ActiveRecord::Schema[8.0].define(version: 2026_09_21_111036) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "countries", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.bigint "currency_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_countries_on_code", unique: true
    t.index ["currency_id"], name: "index_countries_on_currency_id"
  end

  create_table "currencies", force: :cascade do |t|
    t.string "code", null: false
    t.string "name", null: false
    t.string "symbol", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_currencies_on_code", unique: true
  end

  create_table "departments", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_departments_on_code", unique: true
  end

  create_table "employees", force: :cascade do |t|
    t.string "employee_number", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.bigint "department_id", null: false
    t.bigint "job_title_id", null: false
    t.bigint "country_id", null: false
    t.string "employment_status", null: false
    t.date "joined_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["country_id"], name: "index_employees_on_country_id"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_number"], name: "index_employees_on_employee_number", unique: true
    t.index ["job_title_id"], name: "index_employees_on_job_title_id"
  end

  create_table "job_titles", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_job_titles_on_code", unique: true
  end

  create_table "salary_components", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.string "component_type", null: false
    t.string "calculation_type", null: false
    t.boolean "is_taxable", default: false, null: false
    t.boolean "is_active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_salary_components_on_code", unique: true
  end

  create_table "salary_records", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "currency_id", null: false
    t.date "effective_from", null: false
    t.date "effective_to"
    t.string "status", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["currency_id"], name: "index_salary_records_on_currency_id"
    t.index ["employee_id", "effective_from"], name: "index_salary_records_on_employee_id_and_effective_from"
    t.index ["employee_id", "status"], name: "index_salary_records_on_employee_id_and_status"
    t.index ["employee_id"], name: "index_salary_records_on_employee_id"
  end

  add_foreign_key "countries", "currencies"
  add_foreign_key "employees", "countries"
  add_foreign_key "employees", "departments"
  add_foreign_key "employees", "job_titles"
  add_foreign_key "salary_records", "currencies"
  add_foreign_key "salary_records", "employees"
end
