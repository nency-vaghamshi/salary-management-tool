require "rails_helper"

RSpec.describe Department, type: :model do
  subject(:department) { described_class.new(name: "Engineering", code: "ENG") }

  it "is valid with a name and code" do
    expect(department).to be_valid
  end

  it "is invalid without a name" do
    department.name = nil

    expect(department).not_to be_valid
    expect(department.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a code" do
    department.code = nil

    expect(department).not_to be_valid
    expect(department.errors[:code]).to include("can't be blank")
  end

  it "is invalid with a duplicate code" do
    described_class.create!(name: "Engineering", code: "ENG")
    department.name = "Engineering Duplicate"

    expect(department).not_to be_valid
    expect(department.errors[:code]).to include("has already been taken")
  end
end
