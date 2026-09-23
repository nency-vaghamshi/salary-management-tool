FactoryBot.define do
  factory :payroll_line_item do
    payroll_run
    employee
    salary_record
    amount { 70_000.00 }
  end
end
