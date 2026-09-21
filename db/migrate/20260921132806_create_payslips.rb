class CreatePayslips < ActiveRecord::Migration[8.0]
  def change
    create_table :payslips do |t|
      t.references :payroll_run, null: false, foreign_key: true
      t.references :employee, null: false, foreign_key: true
      t.string :payslip_number, null: false
      t.string :status, null: false, default: "generated"
      t.string :document_reference
      t.datetime :generated_at

      t.timestamps
    end

    add_index :payslips, :payslip_number, unique: true
    add_index :payslips, [ :payroll_run_id, :employee_id ], unique: true
  end
end
