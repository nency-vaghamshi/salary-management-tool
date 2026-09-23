class UpdateTaxConfigurationsForTaxYear < ActiveRecord::Migration[8.0]
  def change
    remove_column :tax_configurations, :name, :string
    remove_column :tax_configurations, :tax_type, :string
    remove_column :tax_configurations, :calculation_method, :string
    remove_column :tax_configurations, :rate, :decimal, precision: 10, scale: 4
    remove_column :tax_configurations, :threshold_amount, :decimal, precision: 15, scale: 2
    remove_column :tax_configurations, :effective_from, :date
    remove_column :tax_configurations, :effective_to, :date

    add_column :tax_configurations, :tax_year, :integer, null: false
    add_column :tax_configurations, :status, :string, null: false, default: "active"

    add_index :tax_configurations, [ :country_id, :tax_year ], unique: true
  end
end
