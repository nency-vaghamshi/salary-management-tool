class UpdateEmployeesForMultiCountry < ActiveRecord::Migration[8.0]
  def change
    remove_reference :employees, :country, foreign_key: true

    add_reference :employees, :nationality_country, foreign_key: { to_table: :countries }
    add_reference :employees, :residence_country, foreign_key: { to_table: :countries }
  end
end
