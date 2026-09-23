class DropLegalEntities < ActiveRecord::Migration[8.0]
  def change
    drop_table :legal_entities do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.references :country, null: false, foreign_key: true

      t.timestamps

      t.index :code, unique: true
    end
  end
end
