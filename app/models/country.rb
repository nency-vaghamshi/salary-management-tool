class Country < ApplicationRecord
  belongs_to :currency

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
