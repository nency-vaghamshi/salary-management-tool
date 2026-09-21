class Department < ApplicationRecord
  has_many :employees

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
