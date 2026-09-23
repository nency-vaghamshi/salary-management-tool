class User < ApplicationRecord
  has_secure_password

  enum :role, { hr_manager: "hr_manager" }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
end
