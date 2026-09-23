require "rails_helper"

RSpec.describe SalaryComponent, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:salary_component)).to be_valid
  end

  it "is invalid without a name" do
    component = build_stubbed(:salary_component, name: nil)

    expect(component).not_to be_valid
    expect(component.errors[:name]).to include("can't be blank")
  end

  it "is invalid without a code" do
    component = build_stubbed(:salary_component, code: nil)

    expect(component).not_to be_valid
    expect(component.errors[:code]).to include("can't be blank")
  end

  it "is invalid with a duplicate code" do
    create(:salary_component, code: "BASIC")
    duplicate = build(:salary_component, code: "BASIC")

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:code]).to include("has already been taken")
  end

  it "rejects a component_type outside earning/deduction" do
    expect { build_stubbed(:salary_component, component_type: "bonus") }.to raise_error(ArgumentError)
  end

  it "rejects a calculation_type outside fixed/percentage/calculated" do
    expect { build_stubbed(:salary_component, calculation_type: "tiered") }.to raise_error(ArgumentError)
  end

  it "defaults is_active to true" do
    expect(SalaryComponent.new.is_active).to eq(true)
  end

  it "defaults is_taxable to false" do
    expect(SalaryComponent.new.is_taxable).to eq(false)
  end
end
