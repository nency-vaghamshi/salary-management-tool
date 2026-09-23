FactoryBot.define do
  factory :salary_record do
    employment
    currency
    effective_from { Date.new(2024, 4, 1) }
    effective_to { nil }
    status { "active" }
  end
end
