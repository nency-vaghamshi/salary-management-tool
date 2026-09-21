require "rails_helper"

RSpec.describe SalaryComponent, type: :model do
  def build_component(attributes = {})
    SalaryComponent.new(
      {
        name: "Basic Salary",
        code: "BASIC",
        component_type: "earning",
        calculation_type: "fixed",
        is_taxable: true,
        is_active: true
      }.merge(attributes)
    )
  end

  it "is valid with all required attributes" do
    expect(build_component).to be_valid
  end

  it "is invalid without a name" do
    component = build_component(name: nil)

    expect(component).not_to be_valid
    expect(component.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a code" do
    component = build_component(code: nil)

    expect(component).not_to be_valid
    expect(component.errors[:code]).to include("can't be blank")
  end

  it "is invalid with a duplicate code" do
    build_component.save!
    duplicate = build_component(name: "Basic Salary Duplicate")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:code]).to include("has already been taken")
  end

  it "rejects a component_type outside earning/deduction" do
    expect { build_component(component_type: "bonus") }.to raise_error(ArgumentError)
  end

  it "rejects a calculation_type outside fixed/percentage/calculated" do
    expect { build_component(calculation_type: "tiered") }.to raise_error(ArgumentError)
  end

  it "defaults is_active to true" do
    component = SalaryComponent.new(name: "Basic Salary", code: "BASIC", component_type: "earning", calculation_type: "fixed")

    expect(component.is_active).to eq(true)
  end

  it "defaults is_taxable to false" do
    component = SalaryComponent.new(name: "Provident Fund", code: "PF", component_type: "deduction", calculation_type: "percentage")

    expect(component.is_taxable).to eq(false)
  end
end
