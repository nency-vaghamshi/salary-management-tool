class TaxConfiguration < ApplicationRecord
  belongs_to :country

  has_many :tax_brackets, dependent: :destroy

  enum :status, { active: "active", inactive: "inactive" }

  validates :tax_year, presence: true
  validates :tax_year, uniqueness: { scope: :country_id }
end
