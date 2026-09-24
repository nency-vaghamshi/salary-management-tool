class HrUserSeeder
  DEFAULT_EMAIL = "hr@acme.test".freeze
  DEFAULT_PASSWORD = "SecurePass123!".freeze

  def self.call
    new.call
  end

  def call
    User.find_or_create_by!(email: DEFAULT_EMAIL) do |user|
      user.name = "HR Manager"
      user.password = DEFAULT_PASSWORD
      user.password_confirmation = DEFAULT_PASSWORD
    end
  end
end
