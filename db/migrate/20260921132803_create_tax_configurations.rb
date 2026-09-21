class CreateTaxConfigurations < ActiveRecord::Migration[8.0]
  def change
    create_table :tax_configurations do |t|
      t.references :country, null: false, foreign_key: true
      t.string :name, null: false
      t.string :tax_type, null: false
      t.string :calculation_method, null: false
      t.decimal :rate, precision: 10, scale: 4
      t.decimal :threshold_amount, precision: 15, scale: 2
      t.date :effective_from, null: false
      t.date :effective_to

      t.timestamps
    end
  end
end
