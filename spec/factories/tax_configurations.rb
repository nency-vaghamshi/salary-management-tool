FactoryBot.define do
  factory :tax_configuration do
    country { association :country, :india }
    tax_year { 2025 }
    status { "active" }
  end
end
