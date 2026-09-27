require "rails_helper"

# Exercises the Postgres triggers from AddSalaryLedgerImmutabilityTriggers.
# Writes go through update_columns / update_all on purpose: they skip model
# validations and callbacks, so any rejection here comes from the database.
RSpec.describe "Salary ledger immutability (database triggers)" do
  let(:salary_record) { create(:salary_record) }

  def raise_trigger_error(message)
    raise_error(ActiveRecord::StatementInvalid, /#{message}/)
  end

  describe "an active salary record" do
    it "can be closed by setting effective_to and status, as a salary revision does" do
      salary_record.update_columns(effective_to: Date.new(2024, 12, 31), status: "inactive")

      expect(salary_record.reload).to be_inactive
    end

    it "rejects changing the currency" do
      other_currency = create(:currency)

      expect { salary_record.update_columns(currency_id: other_currency.id) }
        .to raise_trigger_error("terms cannot be changed")
    end

    it "rejects changing effective_from" do
      expect { salary_record.update_columns(effective_from: Date.new(2023, 1, 1)) }
        .to raise_trigger_error("terms cannot be changed")
    end

    it "rejects moving it to another employment" do
      other_employment = create(:employment)

      expect { salary_record.update_columns(employment_id: other_employment.id) }
        .to raise_trigger_error("terms cannot be changed")
    end
  end

  describe "an inactive salary record" do
    before { salary_record.update_columns(effective_to: Date.new(2024, 12, 31), status: "inactive") }

    it "rejects any change" do
      expect { salary_record.update_columns(effective_to: Date.new(2025, 1, 31)) }
        .to raise_trigger_error("is inactive and cannot be modified")
    end

    it "rejects being reactivated" do
      expect { salary_record.update_columns(status: "active") }
        .to raise_trigger_error("is inactive and cannot be modified")
    end
  end

  describe "a salary record component" do
    let!(:component) { create(:salary_record_component, salary_record: salary_record) }

    it "rejects changing the amount" do
      expect { component.update_columns(amount: 1) }
        .to raise_trigger_error("cannot be modified")
    end

    it "rejects bulk updates that bypass the model" do
      expect { SalaryRecordComponent.where(id: component.id).update_all(amount: 1) }
        .to raise_trigger_error("cannot be modified")
    end
  end

  describe "deletes, which stay allowed so employees can still be removed" do
    it "cascades an employee delete through salary records and components" do
      create(:salary_record_component, salary_record: salary_record)
      employee = salary_record.employment.employee

      employee.destroy!

      expect(SalaryRecord.exists?(salary_record.id)).to be(false)
      expect(SalaryRecordComponent.where(salary_record_id: salary_record.id)).to be_empty
    end
  end

  it "still lets SalaryRevisionService close the current record and open a new one" do
    component = create(:salary_component, :basic_salary)

    result = SalaryRevisionService.new(
      employment: salary_record.employment,
      currency: salary_record.currency,
      effective_from: Date.new(2025, 1, 1),
      component_amounts: { component => 90_000 }
    ).call

    expect(result).to be_success
    expect(salary_record.reload).to be_inactive
  end
end
