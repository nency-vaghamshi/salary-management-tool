class CreatePayrollRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :payroll_runs do |t|
      t.date :period_start, null: false
      t.date :period_end, null: false
      t.string :status, null: false, default: "draft"
      t.datetime :processed_at

      t.timestamps
    end

    add_index :payroll_runs, :period_start
    add_index :payroll_runs, :period_end
    add_index :payroll_runs, :status
    add_index :payroll_runs, [ :period_start, :period_end ], unique: true
  end
end
