class CreateTaxBrackets < ActiveRecord::Migration[8.0]
  def change
    create_table :tax_brackets do |t|
      t.references :tax_configuration, null: false, foreign_key: true
      t.decimal :min_income, precision: 15, scale: 2, null: false
      t.decimal :max_income, precision: 15, scale: 2
      t.decimal :tax_rate, precision: 5, scale: 2, null: false

      t.timestamps
    end

    add_index :tax_brackets, [ :tax_configuration_id, :min_income ]
  end
end
