require "rails_helper"

RSpec.describe Department, type: :model do
  it "is valid with a name and code" do
    expect(build_stubbed(:department)).to be_valid
  end

  it "is invalid without a name" do
    department = build_stubbed(:department, name: nil)

    expect(department).not_to be_valid
    expect(department.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a code" do
    department = build_stubbed(:department, code: nil)

    expect(department).not_to be_valid
    expect(department.errors[:code]).to include("can't be blank")
  end

  it "is invalid with a duplicate code" do
    create(:department, code: "ENG")
    duplicate = build(:department, code: "ENG")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:code]).to include("has already been taken")
  end

  it "has many employees" do
    department = create(:department, :engineering)
    employee = create(:employee, department: department)

    expect(department.employees).to include(employee)
  end
end
