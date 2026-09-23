class CreateTaxDataImports < ActiveRecord::Migration[8.0]
  def change
    create_table :tax_data_imports do |t|
      t.string :source, null: false
      t.integer :tax_year, null: false
      t.datetime :imported_at
      t.string :status, null: false, default: "pending"
      t.jsonb :raw_data, null: false, default: {}

      t.timestamps
    end

    add_index :tax_data_imports, [ :source, :tax_year ]
  end
end
