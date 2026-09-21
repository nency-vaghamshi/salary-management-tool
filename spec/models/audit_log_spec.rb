require "rails_helper"

RSpec.describe AuditLog, type: :model do
  let(:currency) { Currency.create!(code: "USD", name: "US Dollar", symbol: "$") }
  let(:country) { Country.create!(name: "United States", code: "US", currency: currency) }
  let(:department) { Department.create!(name: "Engineering", code: "ENG") }
  let(:job_title) { JobTitle.create!(name: "Software Engineer", code: "SWE") }
  let(:employee) do
    Employee.create!(
      employee_number: "EMP-1001",
      first_name: "Ada",
      last_name: "Lovelace",
      email: "ada@example.com",
      department: department,
      job_title: job_title,
      country: country,
      joined_on: Date.new(2024, 4, 1)
    )
  end

  def build_audit_log(attributes = {})
    AuditLog.new(
      {
        actor_id: 42,
        action: "update",
        auditable: employee,
        audited_changes: { "employment_status" => %w[active inactive] }
      }.merge(attributes)
    )
  end

  it "is valid with all required attributes" do
    expect(build_audit_log).to be_valid
  end

  it "is invalid without an action" do
    audit_log = build_audit_log(action: nil)

    expect(audit_log).not_to be_valid
    expect(audit_log.errors[:action]).to include("can't be blank")
  end

  it "is invalid without an auditable record" do
    audit_log = build_audit_log(auditable: nil)

    expect(audit_log).not_to be_valid
    expect(audit_log.errors[:auditable]).to include("must exist")
  end

  it "is invalid without audited_changes" do
    audit_log = build_audit_log(audited_changes: nil)

    expect(audit_log).not_to be_valid
    expect(audit_log.errors[:audited_changes]).to include("can't be blank")
  end

  it "is valid without an actor_id" do
    audit_log = build_audit_log(actor_id: nil)

    expect(audit_log).to be_valid
  end

  it "is append-only: it cannot be updated after creation" do
    audit_log = build_audit_log
    audit_log.save!

    expect { audit_log.update!(action: "delete") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "is append-only: it cannot be destroyed" do
    audit_log = build_audit_log
    audit_log.save!

    expect { audit_log.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
