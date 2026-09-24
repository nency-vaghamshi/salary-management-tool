# Devise's password reset, adapted to this app's JWT sign-in: the pages are
# public, use the sign-in layout, and send the user back to /login (Devise's
# own session routes are not mounted).
class Users::PasswordsController < Devise::PasswordsController
  skip_before_action :authenticate_user!
  layout "sessions"

  protected

  def after_sending_reset_password_instructions_path_for(_resource_name)
    login_path
  end

  def after_resetting_password_path_for(_resource)
    login_path
  end
end
