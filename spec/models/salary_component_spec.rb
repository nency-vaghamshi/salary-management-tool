require "rails_helper"

RSpec.describe SalaryComponent, type: :model do
  subject(:salary_component) do
    described_class.new(
      name: "Basic Salary",
      code: "BASIC",
      component_type: "earning",
      calculation_type: "fixed",
      is_taxable: true,
      is_active: true
    )
  end

  it "is valid with all required attributes" do
    expect(salary_component).to be_valid
  end

  it "is invalid without a component_type" do
    salary_component.component_type = nil

    expect(salary_component).not_to be_valid
    expect(salary_component.errors[:component_type]).to include("can't be blank")
  end

  it "is invalid with a component_type outside earning/deduction" do
    salary_component.component_type = "bonus_credit"

    expect(salary_component).not_to be_valid
    expect(salary_component.errors[:component_type]).to include("is not included in the list")
  end

  it "is invalid without a calculation_type" do
    salary_component.calculation_type = nil

    expect(salary_component).not_to be_valid
    expect(salary_component.errors[:calculation_type]).to include("can't be blank")
  end

  it "is invalid with a calculation_type outside fixed/percentage/calculated" do
    salary_component.calculation_type = "custom"

    expect(salary_component).not_to be_valid
    expect(salary_component.errors[:calculation_type]).to include("is not included in the list")
  end

  it "defaults is_taxable to false" do
    expect(described_class.new.is_taxable).to eq(false)
  end

  it "defaults is_active to true" do
    expect(described_class.new.is_active).to eq(true)
  end
end
