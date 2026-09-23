FactoryBot.define do
  factory :country do
    sequence(:name) { |n| "Country #{n}" }
    sequence(:code) { |n| "C#{n}" }
    currency

    trait :united_states do
      name { "United States" }
      code { "US" }
      currency { association :currency, :usd }
    end

    trait :india do
      name { "India" }
      code { "IN" }
      currency { association :currency, :inr }
    end
  end
end
