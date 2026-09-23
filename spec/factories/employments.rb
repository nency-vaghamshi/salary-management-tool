FactoryBot.define do
  factory :employment do
    employee
    payroll_country { association :country }
    start_date { Date.new(2024, 4, 1) }
    end_date { nil }
    status { "active" }
  end
end
