class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable, :omniauthable, omniauth_providers: [ :google_oauth2 ],
         jwt_revocation_strategy: self

  enum :role, { hr_manager: "hr_manager" }

  validates :name, presence: true

  # Links by email when the address already has a password account, so one
  # person never ends up with two users.
  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid) || find_or_initialize_by(email: auth.info.email)
    user.assign_attributes(provider: auth.provider, uid: auth.uid)
    if user.new_record?
      user.name = auth.info.name.presence || auth.info.email
      user.password = Devise.friendly_token[0, 20]
    end
    user.save
    user
  end
end
