class SalaryComponent < ApplicationRecord
  include HasUniqueCode

  COMPONENT_TYPES = %w[earning deduction].freeze
  CALCULATION_TYPES = %w[fixed percentage calculated].freeze

  validates :component_type, presence: true, inclusion: { in: COMPONENT_TYPES }
  validates :calculation_type, presence: true, inclusion: { in: CALCULATION_TYPES }
end
