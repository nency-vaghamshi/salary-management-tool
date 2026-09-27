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

  it "is valid without an actor, for changes made outside a signed-in request" do
    expect(build_stubbed(:audit_log, actor: nil)).to be_valid
  end

  describe "#actor_name" do
    it "returns the actor's name" do
      audit_log = build_stubbed(:audit_log, actor: build_stubbed(:user, name: "Grace Hopper"))

      expect(audit_log.actor_name).to eq("Grace Hopper")
    end

    it "falls back to System when there is no actor" do
      expect(build_stubbed(:audit_log, actor: nil).actor_name).to eq("System")
    end
  end

  describe ".creations_of" do
    it "returns only the created entries for the given records" do
      employee = create(:employee)
      other_employee = create(:employee)
      employee.update!(first_name: "Changed")

      creations = described_class.creations_of([ employee ])

      expect(creations.map(&:auditable)).to eq([ employee ])
      expect(creations.map(&:action)).to eq([ "created" ])
      expect(creations.map(&:auditable)).not_to include(other_employee)
    end
  end

  describe "append-only trail" do
    it "cannot be updated after creation" do
      audit_log = create(:audit_log)

      expect { audit_log.update!(action: "destroyed") }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it "cannot be destroyed" do
      audit_log = create(:audit_log)

      expect { audit_log.destroy! }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end
end
