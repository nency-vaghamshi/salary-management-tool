FactoryBot.define do
  factory :tax_bracket do
    tax_configuration
    min_income { 0 }
    max_income { 250_000 }
    tax_rate { 5 }
  end
end
