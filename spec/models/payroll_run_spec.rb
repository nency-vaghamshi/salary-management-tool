require "rails_helper"

RSpec.describe PayrollRun, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:payroll_run)).to be_valid
  end

  it "is invalid without a period_start" do
    payroll_run = build_stubbed(:payroll_run, period_start: nil)

    expect(payroll_run).not_to be_valid
    expect(payroll_run.errors[:period_start]).to include("can't be blank")
  end

  it "is invalid without a period_end" do
    payroll_run = build_stubbed(:payroll_run, period_end: nil)

    expect(payroll_run).not_to be_valid
    expect(payroll_run.errors[:period_end]).to include("can't be blank")
  end

  it "is invalid when period_end is before period_start" do
    payroll_run = build_stubbed(:payroll_run, period_start: Date.new(2026, 9, 30), period_end: Date.new(2026, 9, 1))

    expect(payroll_run).not_to be_valid
    expect(payroll_run.errors[:period_end]).to include("must be on or after the period_start date")
  end

  it "is invalid with a duplicate period" do
    create(:payroll_run, period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30))
    duplicate = build(:payroll_run, period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30))

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:period_start]).to include("has already been taken for this period")
  end

  it "defaults to the draft status" do
    expect(PayrollRun.new.status).to eq("draft")
  end

  it "rejects a status outside the defined set" do
    expect { build_stubbed(:payroll_run, status: "cancelled") }.to raise_error(ArgumentError)
  end

  it "has many payslips through payroll_line_items" do
    payroll_run = create(:payroll_run)
    line_item = create(:payroll_line_item, payroll_run: payroll_run)
    payslip = create(:payslip, payroll_line_item: line_item)

    expect(payroll_run.payslips).to include(payslip)
  end

  it "allows the same period_start with a different period_end" do
    create(:payroll_run, period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30))

    expect(build(:payroll_run, period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 15))).to be_valid
  end

  it "is valid when period_end equals period_start, a one-day run" do
    expect(build_stubbed(:payroll_run, period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 1))).to be_valid
  end

  it "destroys dependent payroll_line_items when destroyed" do
    line_item = create(:payroll_line_item)

    expect { line_item.payroll_run.destroy! }.to change(PayrollLineItem, :count).by(-1)
  end

  describe "#period_days" do
    it "counts both the first and last day of the period" do
      run = build_stubbed(:payroll_run, period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30))

      expect(run.period_days).to eq(30)
    end

    it "is 1 for a single-day run" do
      run = build_stubbed(:payroll_run, period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 1))

      expect(run.period_days).to eq(1)
    end
  end

  describe "#proration_factor" do
    it "is the period's share of a 365-day year" do
      run = build_stubbed(:payroll_run, period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30))

      expect(run.proration_factor).to eq(30.to_d / 365)
    end

    it "uses 366 days when the period starts in a leap year" do
      run = build_stubbed(:payroll_run, period_start: Date.new(2024, 2, 1), period_end: Date.new(2024, 2, 29))

      expect(run.proration_factor).to eq(29.to_d / 366)
    end

    it "is exactly 1 for a full calendar year" do
      run = build_stubbed(:payroll_run, period_start: Date.new(2026, 1, 1), period_end: Date.new(2026, 12, 31))

      expect(run.proration_factor).to eq(1)
    end

    it "returns a BigDecimal so money math stays exact" do
      run = build_stubbed(:payroll_run, period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30))

      expect(run.proration_factor).to be_a(BigDecimal)
    end
  end
end
