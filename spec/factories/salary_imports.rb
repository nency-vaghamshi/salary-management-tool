FactoryBot.define do
  factory :salary_import do
    uploaded_by_id { 1 }
    sequence(:file_name) { |n| "salaries_#{n}.xlsx" }
    status { "pending" }
    total_rows { 0 }
    successful_rows { 0 }
    failed_rows { 0 }
  end
end
