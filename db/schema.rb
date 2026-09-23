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

ActiveRecord::Schema[8.0].define(version: 2026_09_23_183243) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "actor_id"
    t.string "action", null: false
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.jsonb "audited_changes", null: false
    t.datetime "created_at", null: false
    t.index ["actor_id"], name: "index_audit_logs_on_actor_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
  end

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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "nationality_country_id"
    t.bigint "residence_country_id"
    t.index ["department_id"], name: "index_employees_on_department_id"
    t.index ["email"], name: "index_employees_on_email", unique: true
    t.index ["employee_number"], name: "index_employees_on_employee_number", unique: true
    t.index ["job_title_id"], name: "index_employees_on_job_title_id"
    t.index ["nationality_country_id"], name: "index_employees_on_nationality_country_id"
    t.index ["residence_country_id"], name: "index_employees_on_residence_country_id"
  end

  create_table "employments", force: :cascade do |t|
    t.bigint "employee_id", null: false
    t.bigint "payroll_country_id", null: false
    t.date "start_date", null: false
    t.date "end_date"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id", "start_date"], name: "index_employments_on_employee_id_and_start_date"
    t.index ["employee_id", "status"], name: "index_employments_on_employee_id_and_status"
    t.index ["employee_id"], name: "index_employments_on_employee_id"
    t.index ["payroll_country_id"], name: "index_employments_on_payroll_country_id"
  end

  create_table "job_titles", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_job_titles_on_code", unique: true
  end

  create_table "payroll_line_items", force: :cascade do |t|
    t.bigint "payroll_run_id", null: false
    t.bigint "employee_id", null: false
    t.bigint "salary_record_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["employee_id"], name: "index_payroll_line_items_on_employee_id"
    t.index ["payroll_run_id", "employee_id"], name: "index_payroll_line_items_on_payroll_run_id_and_employee_id"
    t.index ["payroll_run_id"], name: "index_payroll_line_items_on_payroll_run_id"
    t.index ["salary_record_id"], name: "index_payroll_line_items_on_salary_record_id"
  end

  create_table "payroll_runs", force: :cascade do |t|
    t.date "period_start", null: false
    t.date "period_end", null: false
    t.string "status", default: "draft", null: false
    t.datetime "processed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["period_end"], name: "index_payroll_runs_on_period_end"
    t.index ["period_start", "period_end"], name: "index_payroll_runs_on_period_start_and_period_end", unique: true
    t.index ["period_start"], name: "index_payroll_runs_on_period_start"
    t.index ["status"], name: "index_payroll_runs_on_status"
  end

  create_table "payslips", force: :cascade do |t|
    t.datetime "generated_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "payroll_line_item_id", null: false
    t.string "document_path"
    t.index ["payroll_line_item_id"], name: "index_payslips_on_payroll_line_item_id", unique: true
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

  create_table "salary_imports", force: :cascade do |t|
    t.bigint "uploaded_by_id", null: false
    t.string "file_name", null: false
    t.string "status", default: "pending", null: false
    t.integer "total_rows", default: 0, null: false
    t.integer "successful_rows", default: 0, null: false
    t.integer "failed_rows", default: 0, null: false
    t.datetime "started_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["uploaded_by_id"], name: "index_salary_imports_on_uploaded_by_id"
  end

  create_table "salary_record_components", force: :cascade do |t|
    t.bigint "salary_record_id", null: false
    t.bigint "salary_component_id", null: false
    t.decimal "amount", precision: 15, scale: 2, null: false
    t.string "calculation_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["salary_component_id"], name: "index_salary_record_components_on_salary_component_id"
    t.index ["salary_record_id", "salary_component_id"], name: "index_salary_record_components_on_record_and_component", unique: true
    t.index ["salary_record_id"], name: "index_salary_record_components_on_salary_record_id"
  end

  create_table "salary_records", force: :cascade do |t|
    t.bigint "currency_id", null: false
    t.date "effective_from", null: false
    t.date "effective_to"
    t.string "status", default: "active", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "employment_id", null: false
    t.index ["currency_id"], name: "index_salary_records_on_currency_id"
    t.index ["employment_id", "effective_from"], name: "index_salary_records_on_employment_id_and_effective_from"
    t.index ["employment_id", "status"], name: "index_salary_records_on_employment_id_and_status"
    t.index ["employment_id"], name: "index_salary_records_on_employment_id"
  end

  create_table "tax_brackets", force: :cascade do |t|
    t.bigint "tax_configuration_id", null: false
    t.decimal "min_income", precision: 15, scale: 2, null: false
    t.decimal "max_income", precision: 15, scale: 2
    t.decimal "tax_rate", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tax_configuration_id", "min_income"], name: "index_tax_brackets_on_tax_configuration_id_and_min_income"
    t.index ["tax_configuration_id"], name: "index_tax_brackets_on_tax_configuration_id"
  end

  create_table "tax_configurations", force: :cascade do |t|
    t.bigint "country_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tax_year", null: false
    t.string "status", default: "active", null: false
    t.index ["country_id", "tax_year"], name: "index_tax_configurations_on_country_id_and_tax_year", unique: true
    t.index ["country_id"], name: "index_tax_configurations_on_country_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.string "role", default: "hr_manager", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "encrypted_password", default: "", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "countries", "currencies"
  add_foreign_key "employees", "countries", column: "nationality_country_id"
  add_foreign_key "employees", "countries", column: "residence_country_id"
  add_foreign_key "employees", "departments"
  add_foreign_key "employees", "job_titles"
  add_foreign_key "employments", "countries", column: "payroll_country_id"
  add_foreign_key "employments", "employees"
  add_foreign_key "payroll_line_items", "employees"
  add_foreign_key "payroll_line_items", "payroll_runs"
  add_foreign_key "payroll_line_items", "salary_records"
  add_foreign_key "payslips", "payroll_line_items"
  add_foreign_key "salary_record_components", "salary_components"
  add_foreign_key "salary_record_components", "salary_records"
  add_foreign_key "salary_records", "currencies"
  add_foreign_key "salary_records", "employments"
  add_foreign_key "tax_brackets", "tax_configurations"
  add_foreign_key "tax_configurations", "countries"
end
