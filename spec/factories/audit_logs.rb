FactoryBot.define do
  factory :audit_log do
    actor { nil }
    action { "updated" }
    association :auditable, factory: :employee
    audited_changes { { "email" => %w[old@example.com new@example.com] } }
  end
end
