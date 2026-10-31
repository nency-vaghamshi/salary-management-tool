# Throwaway values for request specs that need a second, distinct value
# (a new name, an unknown email) without hardcoding literals in the spec.
FactoryBot.define do
  sequence(:person_name) { |n| "#{Faker::Name.first_name} #{Faker::Name.last_name} #{n}" }
  sequence(:unused_email) { |n| "unused#{n}@example.test" }
end
