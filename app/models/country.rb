class Country < ApplicationRecord
  belongs_to :currency

  has_many :employees

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
