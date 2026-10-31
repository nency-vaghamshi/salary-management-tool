
# Devise's password reset, adapted to this app's JWT sign-in: the pages are
# public, use the sign-in layout, and send the user back to sign in.
class Users::PasswordsController < Devise::PasswordsController
  skip_before_action :authenticate_user!
  layout "sessions"

  protected

  def after_sending_reset_password_instructions_path_for(_resource_name)
    new_user_session_path
  end

  def after_resetting_password_path_for(_resource)
    new_user_session_path
  end
end
