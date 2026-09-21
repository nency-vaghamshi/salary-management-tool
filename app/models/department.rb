class Department < ApplicationRecord
  include HasUniqueCode

  has_many :employees, dependent: :restrict_with_error
end
