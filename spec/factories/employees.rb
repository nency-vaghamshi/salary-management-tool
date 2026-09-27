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
  
    # An employee who can actually be paid: a payroll country with a flat-rate
    # tax bracket, an active employment, and one taxable salary component.
    trait :with_salary do
      transient do
        currency { nil }
        salary_amount { 100_000 }
        tax_rate { 10 }
      end

      after(:create) do |employee, evaluator|
        currency = evaluator.currency || create(:currency)
        country = create(:country, currency: currency)
        tax_configuration = create(:tax_configuration, country: country)
        create(:tax_bracket, tax_configuration: tax_configuration, min_income: 0, max_income: nil, tax_rate: evaluator.tax_rate)

        employment = create(:employment, employee: employee, payroll_country: country)
        salary_record = create(:salary_record, employment: employment, currency: currency)
        create(:salary_record_component, salary_record: salary_record,
                                         salary_component: create(:salary_component, is_taxable: true),
                                         amount: evaluator.salary_amount)
        employee.employments.reset
      end
    end
  end
end
