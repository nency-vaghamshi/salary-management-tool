# Browser pages can't attach an Authorization header on a normal page load, so
# the web UI keeps the same devise-jwt token in an HttpOnly cookie (out of
# reach of XSS). SameSite=Lax stops browsers sending it on cross-site POST/DELETE.
module JwtCookie
  COOKIE_NAME = :jwt

  private

  # Devise would also remember the user in the Rails session cookie, which would
  # authenticate requests (including the CSRF-exempt API) without the token.
  def sign_in(resource_or_scope, *args)
    options = args.extract_options!
    super(resource_or_scope, *args, options.merge(store: false))
  end

  def set_jwt_cookie(user)
    token, _payload = Warden::JWTAuth::UserEncoder.new.call(user, :user, nil)
    cookies.signed[COOKIE_NAME] = {
      value: token,
      expires: Warden::JWTAuth.config.expiration_time.seconds.from_now,
      httponly: true,
      same_site: :lax,
      secure: Rails.env.production?
    }
  end

  def clear_jwt_cookie
    cookies.delete(COOKIE_NAME)
  end
end
