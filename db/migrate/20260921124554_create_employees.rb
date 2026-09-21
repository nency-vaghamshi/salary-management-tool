class CreateEmployees < ActiveRecord::Migration[8.0]
  def change
    create_table :employees do |t|
      t.string :employee_number, null: false
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email, null: false
      t.references :department, null: false, foreign_key: true
      t.references :job_title, null: false, foreign_key: true
      t.references :country, null: false, foreign_key: true
      t.string :employment_status, null: false
      t.date :joined_on, null: false

      t.timestamps
    end
    add_index :employees, :employee_number, unique: true
    add_index :employees, :email, unique: true
  end
end
