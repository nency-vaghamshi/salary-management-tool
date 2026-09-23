FactoryBot.define do
  factory :user do
    name { "Grace Hopper" }
    sequence(:email) { |n| "hr#{n}@example.com" }
    password { "SecurePass123!" }
    role { "hr_manager" }
  end
end
