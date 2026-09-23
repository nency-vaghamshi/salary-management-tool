FactoryBot.define do
  factory :salary_component do
    sequence(:name) { |n| "Salary Component #{n}" }
    sequence(:code) { |n| "COMP#{n}" }
    component_type { "earning" }
    calculation_type { "fixed" }
    is_taxable { true }
    is_active { true }

    trait :basic_salary do
      name { "Basic Salary" }
      code { "BASIC" }
      component_type { "earning" }
      calculation_type { "fixed" }
    end

    trait :provident_fund do
      name { "Provident Fund" }
      code { "PF" }
      component_type { "deduction" }
      calculation_type { "percentage" }
      is_taxable { false }
    end
  end
end
