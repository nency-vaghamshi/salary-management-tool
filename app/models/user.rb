class User < ApplicationRecord
  devise :database_authenticatable, :recoverable, :validatable

  enum :role, { hr_manager: "hr_manager" }

  validates :name, presence: true
end
