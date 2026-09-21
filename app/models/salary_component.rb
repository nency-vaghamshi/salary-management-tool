class SalaryComponent < ApplicationRecord
  enum :component_type, { earning: "earning", deduction: "deduction" }
  enum :calculation_type, { fixed: "fixed", percentage: "percentage", calculated: "calculated" }

  validates :name, presence: true
  validates :code, presence: true, uniqueness: true
end
