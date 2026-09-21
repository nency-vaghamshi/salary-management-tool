class Currency < ApplicationRecord
  include HasUniqueCode

  has_many :countries, dependent: :restrict_with_error

  validates :symbol, presence: true
end
