require "rails_helper"

RSpec.describe SalaryRecordComponent, type: :model do
  it "is valid with all required attributes" do
    expect(build_stubbed(:salary_record_component)).to be_valid
  end

  it "is invalid without a salary_record" do
    line = build_stubbed(:salary_record_component, salary_record: nil)

    expect(line).not_to be_valid
    expect(line.errors[:salary_record]).to include("must exist")
  end

  it "is invalid without a salary_component" do
    line = build_stubbed(:salary_record_component, salary_component: nil)

    expect(line).not_to be_valid
    expect(line.errors[:salary_component]).to include("must exist")
  end

  it "is invalid without an amount" do
    line = build_stubbed(:salary_record_component, amount: nil)

    expect(line).not_to be_valid
    expect(line.errors[:amount]).to include("can't be blank")
  end

  it "is invalid with a negative amount" do
    line = build_stubbed(:salary_record_component, amount: -100)

    expect(line).not_to be_valid
    expect(line.errors[:amount]).to include("must be greater than or equal to 0")
  end

  it "is invalid when the same component appears twice in the same salary record" do
    salary_record = create(:salary_record)
    salary_component = create(:salary_component, :basic_salary)
    create(:salary_record_component, salary_record: salary_record, salary_component: salary_component)
    duplicate = build(:salary_record_component, salary_record: salary_record, salary_component: salary_component)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:salary_component_id]).to include("has already been taken")
  end

  it "snapshots calculation_type from the salary_component when not explicitly set" do
    salary_component = create(:salary_component, :basic_salary, calculation_type: "fixed")
    line = create(:salary_record_component, salary_component: salary_component, calculation_type: nil)

    expect(line.calculation_type).to eq("fixed")
  end

  it "allows the calculation_type snapshot to be explicitly overridden" do
    line = create(:salary_record_component, calculation_type: "percentage")

    expect(line.calculation_type).to eq("percentage")
  end
end
