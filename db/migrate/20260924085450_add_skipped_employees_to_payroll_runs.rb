class AddSkippedEmployeesToPayrollRuns < ActiveRecord::Migration[8.0]
  def change
    add_column :payroll_runs, :skipped_employees, :jsonb, null: false, default: []
  end
end
