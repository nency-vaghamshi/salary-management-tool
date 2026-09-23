class CreateLegalEntities < ActiveRecord::Migration[8.0]
  def change
    create_table :legal_entities do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.references :country, null: false, foreign_key: true

      t.timestamps
    end

    add_index :legal_entities, :code, unique: true
  end
end
