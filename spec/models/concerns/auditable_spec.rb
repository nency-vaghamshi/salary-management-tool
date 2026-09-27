require "rails_helper"

# Exercised through Employee, the simplest model that includes the concern.
RSpec.describe Auditable do
  let(:hr_user) { create(:user) }

  after { Current.reset }

  def audit_logs_for(record)
    AuditLog.where(auditable_type: record.class.name, auditable_id: record.id).order(:id)
  end

  it "is included in the models whose history must be traceable" do
    expect(Employee.include?(described_class)).to be(true)
    expect(SalaryRecord.include?(described_class)).to be(true)
  end

  describe "on create" do
    it "records a created entry attributed to the signed-in user" do
      Current.user = hr_user

      employee = create(:employee, first_name: "Ada")

      log = audit_logs_for(employee).sole
      expect(log.action).to eq("created")
      expect(log.actor).to eq(hr_user)
      expect(log.audited_changes["first_name"]).to eq([ nil, "Ada" ])
    end

    it "leaves the actor empty when no user is signed in" do
      employee = create(:employee)

      expect(audit_logs_for(employee).sole.actor).to be_nil
    end

    it "does not record timestamps as changes" do
      employee = create(:employee)

      expect(audit_logs_for(employee).sole.audited_changes.keys).not_to include("created_at", "updated_at")
    end
  end

  describe "on update" do
    it "records only the attributes that changed, as before/after pairs" do
      employee = create(:employee, first_name: "Ada")

      employee.update!(first_name: "Grace")

      log = audit_logs_for(employee).last
      expect(log.action).to eq("updated")
      expect(log.audited_changes).to eq("first_name" => %w[Ada Grace])
    end

    it "records nothing when only timestamps change" do
      employee = create(:employee)

      expect { employee.update!(updated_at: 1.day.from_now) }.not_to change(AuditLog, :count)
    end
  end

  describe "on destroy" do
    it "records a snapshot of what existed, since there is no before/after diff" do
      employee = create(:employee, first_name: "Ada")

      employee.destroy!

      log = audit_logs_for(employee).last
      expect(log.action).to eq("destroyed")
      expect(log.audited_changes["first_name"]).to eq([ "Ada", nil ])
      expect(log.audited_changes.keys).not_to include("id", "created_at", "updated_at")
    end
  end
end
