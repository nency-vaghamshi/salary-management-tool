require "rails_helper"

RSpec.describe SalaryImport, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:salary_import)).to be_valid
  end

  it "is invalid without an uploaded_by_id" do
    salary_import = build_stubbed(:salary_import, uploaded_by_id: nil)

    expect(salary_import).not_to be_valid
    expect(salary_import.errors[:uploaded_by_id]).to include("can't be blank")
  end

  it "is invalid without a file_name" do
    salary_import = build_stubbed(:salary_import, file_name: nil)

    expect(salary_import).not_to be_valid
    expect(salary_import.errors[:file_name]).to include("can't be blank")
  end

  it "defaults to the pending status" do
    expect(SalaryImport.new.status).to eq("pending")
  end

  it "rejects a status outside the defined set" do
    expect { build_stubbed(:salary_import, status: "archived") }.to raise_error(ArgumentError)
  end

  it "defaults total_rows, successful_rows, and failed_rows to zero" do
    salary_import = SalaryImport.new

    expect(salary_import.total_rows).to eq(0)
    expect(salary_import.successful_rows).to eq(0)
    expect(salary_import.failed_rows).to eq(0)
  end
end
