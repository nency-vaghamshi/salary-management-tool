class Employee < ApplicationRecord
  include Auditable

  belongs_to :department
  belongs_to :job_title
  belongs_to :nationality_country, class_name: "Country", optional: true
  belongs_to :residence_country, class_name: "Country", optional: true

  has_many :employments, dependent: :destroy
  has_many :salary_records, through: :employments
  has_many :payroll_line_items, dependent: :destroy
  has_many :payslips, through: :payroll_line_items

  accepts_nested_attributes_for :employments

  validates :employee_number, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true

  def full_name
    "#{first_name} #{last_name}"
  end

  # The employment HR currently cares about for this employee: the open-ended
  # one if present, otherwise their most recently started employment.
  def current_employment
    employments.max_by { |employment| [ employment.end_date.nil? ? 1 : 0, employment.start_date ] }
  end

  def current_salary_record
    current_employment&.salary_records&.max_by(&:effective_from)
  end
end
