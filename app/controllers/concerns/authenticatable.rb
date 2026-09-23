module Authenticatable
  extend ActiveSupport::Concern

  included do
    helper_method :current_user if respond_to?(:helper_method)
  end

  private

  def authenticate_user!
    user = authenticated_user
    return render_unauthenticated unless user

    Current.user = user
  end

  def authenticated_user
    token = bearer_token || cookies.signed[:jwt]
    return nil if token.blank?

    payload = JsonWebToken.decode(token)
    User.find_by(id: payload[:user_id])
  rescue JWT::DecodeError
    nil
  end

  def bearer_token
    header = request.headers["Authorization"]
    header.split(" ").last if header&.start_with?("Bearer ")
  end

  def render_unauthenticated
    if request.format.html?
      redirect_to login_path
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end

  def current_user
    Current.user
  end
end
