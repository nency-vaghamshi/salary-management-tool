require "rails_helper"

RSpec.describe PayrollLineItem, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:payroll_line_item)).to be_valid
  end

  it "is invalid without a payroll_run" do
    line_item = build_stubbed(:payroll_line_item, payroll_run: nil)

    expect(line_item).not_to be_valid
    expect(line_item.errors[:payroll_run]).to include("must exist")
  end

  it "is invalid without an employee" do
    line_item = build_stubbed(:payroll_line_item, employee: nil)

    expect(line_item).not_to be_valid
    expect(line_item.errors[:employee]).to include("must exist")
  end

  it "is invalid without a salary_record" do
    line_item = build_stubbed(:payroll_line_item, salary_record: nil)

    expect(line_item).not_to be_valid
    expect(line_item.errors[:salary_record]).to include("must exist")
  end

  it "is invalid without an amount" do
    line_item = build_stubbed(:payroll_line_item, amount: nil)

    expect(line_item).not_to be_valid
    expect(line_item.errors[:amount]).to include("can't be blank")
  end

  it "is invalid with a negative amount" do
    line_item = build_stubbed(:payroll_line_item, amount: -1)

    expect(line_item).not_to be_valid
    expect(line_item.errors[:amount]).to include("must be greater than or equal to 0")
  end

  it "is valid with a zero amount" do
    expect(build_stubbed(:payroll_line_item, amount: 0)).to be_valid
  end

  it "has one payslip" do
    line_item = create(:payroll_line_item)
    payslip = create(:payslip, payroll_line_item: line_item)

    expect(line_item.payslip).to eq(payslip)
  end

  it "destroys the dependent payslip when destroyed" do
    line_item = create(:payroll_line_item)
    payslip = create(:payslip, payroll_line_item: line_item)

    line_item.destroy!

    expect(Payslip.exists?(payslip.id)).to be false
  end
end
