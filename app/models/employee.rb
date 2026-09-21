class Employee < ApplicationRecord
  belongs_to :department
  belongs_to :job_title
  belongs_to :country

  has_many :salary_records, dependent: :destroy

  enum :employment_status, { active: "active", inactive: "inactive", terminated: "terminated" }

  validates :employee_number, presence: true, uniqueness: true
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validates :joined_on, presence: true
end
