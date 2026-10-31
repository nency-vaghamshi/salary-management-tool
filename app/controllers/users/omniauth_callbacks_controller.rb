class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include JwtCookie

  # Google redirects back with a GET, so there is no CSRF token to check; the
  # omniauth state parameter protects this leg instead.
  skip_forgery_protection

  def google_oauth2
    user = User.from_omniauth(request.env["omniauth.auth"])

    if user.persisted?
      sign_in(user)
      set_jwt_cookie(user)
      redirect_to after_sign_in_path_for(user)
    else
      redirect_to new_user_session_path, alert: "Google sign-in failed: #{user.errors.full_messages.to_sentence}"
    end
  end

  def failure
    redirect_to new_user_session_path, alert: "Google sign-in was cancelled or failed."
  end
end
