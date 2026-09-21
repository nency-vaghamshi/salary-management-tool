class CreateJobTitles < ActiveRecord::Migration[8.0]
  def change
    create_table :job_titles do |t|
      t.string :name, null: false
      t.string :code, null: false

      t.timestamps
    end
    add_index :job_titles, :code, unique: true
  end
end
