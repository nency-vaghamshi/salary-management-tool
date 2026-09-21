class Employee < ApplicationRecord
  belongs_to :department
  belongs_to :job_title
  belongs_to :country

  validates :employee_number, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :employment_status, presence: true
  validates :joined_on, presence: true
end
