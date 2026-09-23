require "rails_helper"

RSpec.describe AuditLog, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:audit_log)).to be_valid
  end

  it "is invalid without an action" do
    audit_log = build_stubbed(:audit_log, action: nil)

    expect(audit_log).not_to be_valid
    expect(audit_log.errors[:action]).to include("can't be blank")
  end

  it "is invalid without an auditable record" do
    audit_log = build_stubbed(:audit_log, auditable: nil)

    expect(audit_log).not_to be_valid
    expect(audit_log.errors[:auditable]).to include("must exist")
  end

  it "is invalid without audited_changes" do
    audit_log = build_stubbed(:audit_log, audited_changes: nil)

    expect(audit_log).not_to be_valid
    expect(audit_log.errors[:audited_changes]).to include("can't be blank")
  end

  it "is valid without an actor_id" do
    expect(build_stubbed(:audit_log, actor_id: nil)).to be_valid
  end

  it "is append-only: it cannot be updated after creation" do
    audit_log = create(:audit_log)

    expect { audit_log.update!(action: "delete") }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end

  it "is append-only: it cannot be destroyed" do
    audit_log = create(:audit_log)

    expect { audit_log.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
  end
end
