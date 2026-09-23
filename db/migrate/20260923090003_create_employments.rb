class CreateEmployments < ActiveRecord::Migration[8.0]
  def change
    create_table :employments do |t|
      t.references :employee, null: false, foreign_key: true
      t.references :legal_entity, null: false, foreign_key: true
      t.references :payroll_country, null: false, foreign_key: { to_table: :countries }
      t.references :work_location, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date
      t.string :status, null: false, default: "active"

      t.timestamps
    end

    add_index :employments, [ :employee_id, :start_date ]
    add_index :employments, [ :employee_id, :status ]
  end
end
