class UpdateSalaryRecordsForEmployment < ActiveRecord::Migration[8.0]
  def change
    remove_index :salary_records, [ :employee_id, :effective_from ], if_exists: true
    remove_index :salary_records, [ :employee_id, :status ], if_exists: true
    remove_reference :salary_records, :employee, foreign_key: true

    add_reference :salary_records, :employment, null: false, foreign_key: true
    add_index :salary_records, [ :employment_id, :effective_from ]
    add_index :salary_records, [ :employment_id, :status ]
  end
end
