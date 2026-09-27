require "rails_helper"

RSpec.describe ProcessPayrollRunJob, type: :job do
  let(:run) { create(:payroll_run, period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30)) }

  describe "#perform" do
    it "calculates the run and issues a payslip for every line item" do
      employees = create_list(:employee, 2, :with_salary)

      described_class.perform_now(run.id)

      expect(run.reload).to be_completed
      expect(run.payroll_line_items.map(&:employee)).to match_array(employees)
      expect(run.payslips.count).to eq(2)
    end

    it "does nothing for a run that is no longer a draft, so a duplicate enqueue can't pay twice" do
      create(:employee, :with_salary)
      described_class.perform_now(run.id)

      expect { described_class.perform_now(run.id) }.not_to change(PayrollLineItem, :count)
      expect(run.reload).to be_completed
    end

    it "does nothing when the run was deleted before the job ran" do
      id = run.id
      run.destroy!

      expect { described_class.perform_now(id) }.not_to raise_error
    end

    it "leaves the run failed and surfaces the error when calculation breaks" do
      create(:employee, :with_salary)
      allow(PayrollLineItem).to receive(:insert_all!).and_raise(ActiveRecord::StatementInvalid, "connection lost")

      expect { described_class.perform_now(run.id) }.to raise_error(ActiveRecord::StatementInvalid)

      expect(run.reload).to be_failed
      expect(run.payslips).to be_empty
    end
  end

  describe "enqueuing" do
    it "is queued on the default queue with just the run's id" do
      expect { described_class.perform_later(run.id) }
        .to have_enqueued_job(described_class).with(run.id).on_queue("default")
    end

    it "allows only one job per run at a time" do
      expect(described_class.concurrency_limit).to eq(1)
      expect(described_class.new(run.id).concurrency_key).to eq("ProcessPayrollRunJob/#{run.id}")
    end

    it "lets different runs process in parallel" do
      other_run = create(:payroll_run)

      expect(described_class.new(run.id).concurrency_key).not_to eq(described_class.new(other_run.id).concurrency_key)
    end
  end
end
