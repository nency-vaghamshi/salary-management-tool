class DropTaxDataImports < ActiveRecord::Migration[8.0]
  def change
    drop_table :tax_data_imports do |t|
      t.string :source, null: false
      t.integer :tax_year, null: false
      t.datetime :imported_at
      t.string :status, null: false, default: "pending"
      t.jsonb :raw_data, null: false, default: {}

      t.timestamps

      t.index [ :source, :tax_year ]
    end
  end
end
