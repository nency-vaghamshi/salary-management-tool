require "rails_helper"

RSpec.describe PayrollRun, type: :model do
  def build_payroll_run(attributes = {})
    PayrollRun.new(
      {
        period_start: Date.new(2026, 9, 1),
        period_end: Date.new(2026, 9, 30),
        status: "draft"
      }.merge(attributes)
    )
  end

  it "is valid with all required attributes" do
    expect(build_payroll_run).to be_valid
  end

  it "is invalid without a period_start" do
    payroll_run = build_payroll_run(period_start: nil)

    expect(payroll_run).not_to be_valid
    expect(payroll_run.errors[:period_start]).to include("can't be blank")
  end

  it "is invalid without a period_end" do
    payroll_run = build_payroll_run(period_end: nil)

    expect(payroll_run).not_to be_valid
    expect(payroll_run.errors[:period_end]).to include("can't be blank")
  end

  it "is invalid when period_end is before period_start" do
    payroll_run = build_payroll_run(period_start: Date.new(2026, 9, 30), period_end: Date.new(2026, 9, 1))

    expect(payroll_run).not_to be_valid
    expect(payroll_run.errors[:period_end]).to include("must be on or after the period_start date")
  end

  it "is invalid with a duplicate period" do
    build_payroll_run.save!
    duplicate = build_payroll_run

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:period_start]).to include("has already been taken for this period")
  end

  it "defaults to the draft status" do
    payroll_run = PayrollRun.new(period_start: Date.new(2026, 9, 1), period_end: Date.new(2026, 9, 30))

    expect(payroll_run.status).to eq("draft")
  end

  it "rejects a status outside the defined set" do
    expect { build_payroll_run(status: "cancelled") }.to raise_error(ArgumentError)
  end
end
