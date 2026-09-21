class CreateSalaryRecordComponents < ActiveRecord::Migration[8.0]
  def change
    create_table :salary_record_components do |t|
      t.references :salary_record, null: false, foreign_key: true
      t.references :salary_component, null: false, foreign_key: true
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :calculation_type, null: false

      t.timestamps
    end

    add_index :salary_record_components, [ :salary_record_id, :salary_component_id ], unique: true, name: "index_salary_record_components_on_record_and_component"
  end
end
