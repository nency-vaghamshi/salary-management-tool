class UpdatePayslipsForPayrollLineItem < ActiveRecord::Migration[8.0]
  def change
    remove_index :payslips, [ :payroll_run_id, :employee_id ], unique: true, if_exists: true
    remove_index :payslips, :payslip_number, unique: true, if_exists: true
    remove_reference :payslips, :payroll_run, foreign_key: true
    remove_reference :payslips, :employee, foreign_key: true
    remove_column :payslips, :payslip_number, :string
    remove_column :payslips, :status, :string
    remove_column :payslips, :document_reference, :string

    add_reference :payslips, :payroll_line_item, null: false, foreign_key: true, index: { unique: true }
    add_column :payslips, :document_path, :string
  end
end
