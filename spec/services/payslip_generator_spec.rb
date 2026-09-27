require "rails_helper"

RSpec.describe PayslipGenerator do
  let(:run) { create(:payroll_run, status: "completed") }

  it "issues one payslip per line item and returns how many it issued" do
    line_items = create_list(:payroll_line_item, 2, payroll_run: run)

    expect(described_class.new(run).call).to eq(2)
    expect(Payslip.where(payroll_line_item: line_items).count).to eq(2)
  end

  it "stamps each payslip with its issue time" do
    create(:payroll_line_item, payroll_run: run)

    freeze_time do
      described_class.new(run).call

      expect(Payslip.sole.generated_at).to eq(Time.current)
    end
  end

  it "is idempotent: a rerun issues nothing new" do
    create(:payroll_line_item, payroll_run: run)
    described_class.new(run).call

    expect { expect(described_class.new(run).call).to eq(0) }.not_to change(Payslip, :count)
  end

  it "only issues the payslips that are missing" do
    existing = create(:payroll_line_item, payroll_run: run)
    create(:payslip, payroll_line_item: existing)
    create(:payroll_line_item, payroll_run: run)

    expect(described_class.new(run).call).to eq(1)
  end

  it "leaves other runs' line items alone" do
    create(:payroll_line_item, payroll_run: run)
    create(:payroll_line_item, payroll_run: create(:payroll_run, status: "completed"))

    expect(described_class.new(run).call).to eq(1)
  end

  it "works across several batches" do
    stub_const("#{described_class}::BATCH_SIZE", 1)
    create_list(:payroll_line_item, 3, payroll_run: run)

    expect(described_class.new(run).call).to eq(3)
  end

  it "refuses a run that is not completed" do
    expect { described_class.new(create(:payroll_run, status: "draft")).call }
      .to raise_error(ArgumentError, "Payslips can only be issued for a completed run")
  end
end
