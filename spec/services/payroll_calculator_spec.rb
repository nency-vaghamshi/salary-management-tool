require "rails_helper"

RSpec.describe PayrollCalculator do
  # September 2026: 30 days of a 365-day year.
  let(:run) { create(:payroll_run, period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30)) }
  let(:proration) { 30.to_d / 365 }

  def calculate
    described_class.new(run).call
  end

  context "for a payable employee" do
    # 100,000 a year at a flat 10%: 90,000 net and 10,000 tax annually.
    let!(:employee) { create(:employee, :with_salary, salary_amount: 100_000, tax_rate: 10) }

    it "writes one line item paying the period's share of annual net pay and tax" do
      calculate

      line_item = run.payroll_line_items.sole
      expect(line_item).to have_attributes(employee: employee, salary_record: employee.current_salary_record,
                                           amount: (90_000 * proration).round(2), tax_amount: (10_000 * proration).round(2))
      expect(line_item.amount).to eq(BigDecimal("7397.26"))
    end

    it "marks the run completed and returns the counts" do
      freeze_time do
        result = calculate

        expect(run.reload).to have_attributes(status: "completed", processed_at: Time.current, skipped_employees: [])
        expect(result).to have_attributes(payroll_run: run, processed_count: 1, skipped: [])
      end
    end

    it "pays from the active salary record after a revision" do
      employment = employee.current_employment
      SalaryRevisionService.new(employment: employment, currency: employee.current_salary_record.currency,
                                effective_from: Date.new(2026, 1, 1),
                                component_amounts: { create(:salary_component, is_taxable: true) => 200_000 }).call

      calculate

      expect(run.payroll_line_items.sole.amount).to eq((180_000 * proration).round(2))
    end
  end

  describe "skipped employees" do
    it "skips an employee whose active employment has no salary record" do
      employee = create(:employee, first_name: "Ada", last_name: "Lovelace")
      create(:employment, employee: employee)

      result = calculate

      expect(result.skipped).to eq([ { employee_id: employee.id, employee_name: "Ada Lovelace", reason: "No salary record" } ])
      expect(run.payroll_line_items).to be_empty
    end

    it "skips an employee whose payroll country has no tax configuration" do
      employee = create(:employee)
      employment = create(:employment, employee: employee, payroll_country: create(:country, name: "Nowhere"))
      create(:salary_record_component, salary_record: create(:salary_record, employment: employment))

      expect(calculate.skipped.sole[:reason]).to eq("No tax configuration found for Nowhere")
    end

    it "records skipped employees on the run and still pays everyone else" do
      paid = create(:employee, :with_salary)
      unpaid = create(:employee)
      create(:employment, employee: unpaid)

      calculate

      expect(run.reload.skipped_employees.map { |skip| skip["employee_id"] }).to eq([ unpaid.id ])
      expect(run.payroll_line_items.map(&:employee)).to eq([ paid ])
    end

    it "skips an employee whose calculation raises, instead of failing the whole run" do
      broken = create(:employee, :with_salary)
      paid = create(:employee, :with_salary)
      allow(SalaryTaxEstimator).to receive(:new).and_wrap_original do |original, salary_record|
        raise "corrupt salary data" if salary_record == broken.current_salary_record

        original.call(salary_record)
      end

      result = calculate

      expect(result.skipped).to contain_exactly(a_hash_including(employee_id: broken.id, reason: "corrupt salary data"))
      expect(run.payroll_line_items.map(&:employee)).to eq([ paid ])
      expect(run.reload).to be_completed
    end

    it "does not consider employees without an active employment at all" do
      leaver = create(:employee, :with_salary)
      leaver.current_employment.update!(status: "terminated", end_date: Date.new(2026, 6, 30))

      result = calculate

      expect(result.processed_count).to eq(0)
      expect(result.skipped).to be_empty
    end
  end

  it "flushes line items in batches" do
    stub_const("#{described_class}::BATCH_SIZE", 2)
    create_list(:employee, 3, :with_salary)

    expect(calculate.processed_count).to eq(3)
    expect(run.payroll_line_items.count).to eq(3)
  end

  it "completes a run with nobody to pay" do
    expect(calculate.processed_count).to eq(0)
    expect(run.reload).to be_completed
  end

  it "refuses a run that is not a draft" do
    run.update!(status: "completed")

    expect { calculate }.to raise_error(ArgumentError, "Only a draft payroll run can be processed")
  end

  context "when writing line items fails partway through" do
    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)
      create_list(:employee, 2, :with_salary)

      insert_calls = 0
      allow(PayrollLineItem).to receive(:insert_all!).and_wrap_original do |original, *args|
        insert_calls += 1
        raise ActiveRecord::StatementInvalid, "connection lost" if insert_calls == 2

        original.call(*args)
      end
    end

    it "marks the run failed and re-raises" do
      expect { calculate }.to raise_error(ActiveRecord::StatementInvalid, "connection lost")

      expect(run.reload).to be_failed
    end

    it "rolls back the batches already written, so no partial payroll is left" do
      expect { calculate }.to raise_error(ActiveRecord::StatementInvalid)

      expect(run.payroll_line_items.count).to eq(0)
    end
  end
end
