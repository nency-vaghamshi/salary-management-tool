class TaxBracket < ApplicationRecord
  belongs_to :tax_configuration

  validates :min_income, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :max_income, numericality: { greater_than: :min_income }, allow_nil: true, if: -> { min_income.present? }
  validates :tax_rate, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
