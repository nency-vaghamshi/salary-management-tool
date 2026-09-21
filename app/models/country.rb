class Country < ApplicationRecord
  include HasUniqueCode

  belongs_to :currency
end
