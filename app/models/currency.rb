class Currency < ApplicationRecord
  include HasUniqueCode

  validates :symbol, presence: true
end
