# Authentication itself (authenticate_user!, current_user) comes from Devise and
# devise-jwt. Don't redefine authenticate_user! here: Devise controllers call it
# with options. This concern only feeds devise-jwt the browser's cookie token
# and exposes the signed-in user to model-level code (Auditable) via Current.user.
module Authenticatable
  extend ActiveSupport::Concern
  include JwtCookie

  included do
    before_action :use_cookie_token
    before_action :set_current_user
  end

  private

  # devise-jwt only reads the Authorization header, so promote the cookie token
  # when the client didn't send one. An explicit header always wins.
  def use_cookie_token
    return if request.authorization.present?

    token = cookies.signed[COOKIE_NAME]
    request.headers["Authorization"] = "Bearer #{token}" if token.present?
  end

  def set_current_user
    Current.user = current_user
  end
end
