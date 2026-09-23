FactoryBot.define do
  factory :salary_record_component do
    salary_record
    salary_component { association :salary_component, :basic_salary }
    amount { 70_000.00 }
  end
end
