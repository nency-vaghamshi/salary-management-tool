require "rails_helper"

RSpec.describe Department, type: :model do
  it "is valid with a name and code" do
    department = Department.new(name: "Engineering", code: "ENG")

    expect(department).to be_valid
  end

  it "is invalid without a name" do
    department = Department.new(name: nil, code: "ENG")

    expect(department).not_to be_valid
    expect(department.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a code" do
    department = Department.new(name: "Engineering", code: nil)

    expect(department).not_to be_valid
    expect(department.errors[:code]).to include("can't be blank")
  end

  it "is invalid with a duplicate code" do
    Department.create!(name: "Engineering", code: "ENG")
    duplicate = Department.new(name: "Engineering Duplicate", code: "ENG")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:code]).to include("has already been taken")
  end
end
