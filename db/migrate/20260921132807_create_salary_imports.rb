class CreateSalaryImports < ActiveRecord::Migration[8.0]
  def change
    create_table :salary_imports do |t|
      t.bigint :uploaded_by_id, null: false
      t.string :file_name, null: false
      t.string :status, null: false, default: "pending"
      t.integer :total_rows, null: false, default: 0
      t.integer :successful_rows, null: false, default: 0
      t.integer :failed_rows, null: false, default: 0
      t.datetime :started_at
      t.datetime :completed_at

      t.timestamps
    end

    add_index :salary_imports, :uploaded_by_id
  end
end
