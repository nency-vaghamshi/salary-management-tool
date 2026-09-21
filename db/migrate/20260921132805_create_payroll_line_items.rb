class CreatePayrollLineItems < ActiveRecord::Migration[8.0]
  def change
    create_table :payroll_line_items do |t|
      t.references :payroll_run, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.references :salary_record, null: false, foreign_key: true
      t.references :salary_component, null: false, foreign_key: true
      t.string :component_type, null: false
      t.decimal :amount, precision: 15, scale: 2, null: false

      t.timestamps
    end

    add_index :payroll_line_items, [ :payroll_run_id, :employee_id ]
  end
end
