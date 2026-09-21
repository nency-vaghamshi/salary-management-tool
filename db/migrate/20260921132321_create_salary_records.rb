class CreateSalaryRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :salary_records do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :currency, null: false, foreign_key: true
      t.date :effective_from, null: false
      t.date :effective_to
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :salary_records, [ :employee_id, :effective_from ]
    add_index :salary_records, [ :employee_id, :status ]
  end
end
