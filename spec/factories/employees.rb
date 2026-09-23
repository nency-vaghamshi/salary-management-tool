FactoryBot.define do
  factory :employee do
    sequence(:employee_number) { |n| "EMP-#{1000 + n}" }
    first_name { "Ada" }
    last_name { "Lovelace" }
    sequence(:email) { |n| "employee#{n}@example.com" }
    department
    job_title
    nationality_country { nil }
    residence_country { nil }
  end
end
