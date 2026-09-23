FactoryBot.define do
  factory :payroll_run do
    sequence(:period_start) { |n| Date.new(2026, 1, 1).next_month(n) }
    period_end { period_start&.end_of_month }
    status { "draft" }
  end
end
