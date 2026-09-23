FactoryBot.define do
  factory :job_title do
    sequence(:name) { |n| "Job Title #{n}" }
    sequence(:code) { |n| "JT#{n}" }

    trait :software_engineer do
      name { "Software Engineer" }
      code { "SWE" }
    end
  end
end
