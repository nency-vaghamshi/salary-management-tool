class Employee < ApplicationRecord
  belongs_to :department
  belongs_to :job_title
  belongs_to :nationality_country, class_name: "Country", optional: true
  belongs_to :residence_country, class_name: "Country", optional: true

  has_many :employments, dependent: :destroy
  has_many :salary_records, through: :employments
  has_many :payroll_line_items, dependent: :destroy
  has_many :payslips, through: :payroll_line_items

  validates :employee_number, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
end
