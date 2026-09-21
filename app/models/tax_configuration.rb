class TaxConfiguration < ApplicationRecord
  belongs_to :country

  validates :name, presence: true
  validates :tax_type, presence: true
  validates :calculation_method, presence: true
  validates :effective_from, presence: true
end
