class Country < ApplicationRecord
  include HasUniqueCode

  belongs_to :currency

  has_many :employees, dependent: :restrict_with_error
end
