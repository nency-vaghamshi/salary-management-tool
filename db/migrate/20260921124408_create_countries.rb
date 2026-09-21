class CreateCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :countries do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.references :currency, null: false, foreign_key: true

      t.timestamps
    end
    add_index :countries, :code, unique: true
  end
end
