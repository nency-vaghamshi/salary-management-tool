FactoryBot.define do
  factory :currency do
    sequence(:code) { |n| "C#{n}" }
    sequence(:name) { |n| "Currency #{n}" }
    symbol { "$" }

    trait :usd do
      code { "USD" }
      name { "US Dollar" }
      symbol { "$" }
    end

    trait :inr do
      code { "INR" }
      name { "Indian Rupee" }
      symbol { "₹" }
    end
  end
end
