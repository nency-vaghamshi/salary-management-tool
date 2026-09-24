class SalaryComponentSeeder
  COMPONENTS = [
    { name: "Base Salary", code: "BASE", component_type: "earning", calculation_type: "fixed", is_taxable: true },
    { name: "Bonus", code: "BONUS", component_type: "earning", calculation_type: "fixed", is_taxable: true },
    { name: "Housing Allowance", code: "HOUSING", component_type: "earning", calculation_type: "fixed", is_taxable: false },
    { name: "Transport Allowance", code: "TRANSPORT", component_type: "earning", calculation_type: "fixed", is_taxable: false },
    { name: "Other Allowance", code: "OTHER", component_type: "earning", calculation_type: "fixed", is_taxable: false }
  ].freeze

  def self.call
    new.call
  end

  def call
    COMPONENTS.map do |attributes|
      SalaryComponent.find_or_create_by!(code: attributes[:code]) do |component|
        component.name = attributes[:name]
        component.component_type = attributes[:component_type]
        component.calculation_type = attributes[:calculation_type]
        component.is_taxable = attributes[:is_taxable]
      end
    end
  end
end
