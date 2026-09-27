require "rails_helper"

RSpec.describe SalaryComponentSeeder do
  describe ".call" do
    it "creates every component with its type and tax treatment" do
      expect { described_class.call }.to change(SalaryComponent, :count).by(described_class::COMPONENTS.size)

      base = SalaryComponent.find_by(code: "BASE")
      expect(base).to have_attributes(name: "Base Salary", component_type: "earning", calculation_type: "fixed", is_taxable: true)
      expect(SalaryComponent.find_by(code: "HOUSING").is_taxable).to be(false)
    end

    it "is idempotent" do
      described_class.call

      expect { described_class.call }.not_to change(SalaryComponent, :count)
    end

    it "keeps a component that already exists as it is" do
      create(:salary_component, code: "BONUS", is_taxable: false)

      described_class.call

      expect(SalaryComponent.find_by(code: "BONUS").is_taxable).to be(false)
    end
  end
end
