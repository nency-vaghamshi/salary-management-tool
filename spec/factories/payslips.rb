FactoryBot.define do
  factory :payslip do
    payroll_line_item
    document_path { "/payslips/2026-09/example.pdf" }
    generated_at { Time.current }
  end
end
