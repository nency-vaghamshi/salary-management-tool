class CreateSalaryComponents < ActiveRecord::Migration[8.0]
  def change
    create_table :salary_components do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.string :component_type, null: false
      t.string :calculation_type, null: false
      t.boolean :is_taxable, null: false, default: false
      t.boolean :is_active, null: false, default: true

      t.timestamps
    end
    add_index :salary_components, :code, unique: true
  end
end
