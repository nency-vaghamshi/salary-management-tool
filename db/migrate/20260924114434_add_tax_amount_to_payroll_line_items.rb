class AddTaxAmountToPayrollLineItems < ActiveRecord::Migration[8.0]
  def change
    add_column :payroll_line_items, :tax_amount, :decimal, precision: 15, scale: 2, null: false, default: 0
  end
end
