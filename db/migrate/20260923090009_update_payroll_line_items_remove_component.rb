class UpdatePayrollLineItemsRemoveComponent < ActiveRecord::Migration[8.0]
  def change
    remove_reference :payroll_line_items, :salary_component, foreign_key: true
    remove_column :payroll_line_items, :component_type, :string
  end
end
