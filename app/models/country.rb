class Country < ApplicationRecord
  belongs_to :currency

  has_many :employees
  has_many :tax_configurations, dependent: :destroy

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
