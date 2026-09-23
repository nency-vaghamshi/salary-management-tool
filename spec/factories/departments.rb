FactoryBot.define do
  factory :department do
    sequence(:name) { |n| "Department #{n}" }
    sequence(:code) { |n| "DEPT#{n}" }

    trait :engineering do
      name { "Engineering" }
      code { "ENG" }
    end
  end
end
