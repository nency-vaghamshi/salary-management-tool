class RemoveJoinedOnAndEmploymentStatusFromEmployees < ActiveRecord::Migration[8.0]
  def change
    remove_column :employees, :joined_on, :date, null: false
    remove_column :employees, :employment_status, :string, default: "active", null: false
  end
end
