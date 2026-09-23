class CreateWorkLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :work_locations do |t|
      t.string :name, null: false
      t.references :country, null: false, foreign_key: true
      t.string :address

      t.timestamps
    end
  end
end
