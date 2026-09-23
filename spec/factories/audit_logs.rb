FactoryBot.define do
  factory :audit_log do
    actor_id { 42 }
    action { "update" }
    association :auditable, factory: :employee
    audited_changes { { "email" => %w[old@example.com new@example.com] } }
  end
end
