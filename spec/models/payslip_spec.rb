require "rails_helper"

RSpec.describe Payslip, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:payslip)).to be_valid
  end

  it "is invalid without a payroll_line_item" do
    payslip = build_stubbed(:payslip, payroll_line_item: nil)

    expect(payslip).not_to be_valid
    expect(payslip.errors[:payroll_line_item]).to include("must exist")
  end

  it "is invalid with a duplicate payroll_line_item" do
    payroll_line_item = create(:payroll_line_item)
    create(:payslip, payroll_line_item: payroll_line_item)
    duplicate = build(:payslip, payroll_line_item: payroll_line_item)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:payroll_line_item_id]).to include("has already been taken")
  end

  it "is valid without a document_path or generated_at yet to be set" do
    expect(build_stubbed(:payslip, document_path: nil, generated_at: nil)).to be_valid
  end
end
