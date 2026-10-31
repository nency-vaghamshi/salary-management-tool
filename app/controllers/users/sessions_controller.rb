class Users::SessionsController < Devise::SessionsController
  respond_to :json
  layout "sessions", only: :new
  # The sign-in form and API clients authenticate with credentials, not a session cookie.
  skip_forgery_protection
  skip_before_action :authenticate_user!, raise: false
  skip_before_action :verify_signed_out_user, only: :destroy

  # Devise would hand the form to respond_with, which renders JSON here.
  def new
    self.resource = resource_class.new
  end

  def create
    super { |user| set_jwt_cookie(user) }
  end

  # Devise's "already signed out" guard only looks at the Warden session, which
  # stateless JWT requests never populate, so it would skip the sign-out (and the
  # token revocation). Whether there was a user is captured here instead, because
  # current_user is cleared by the time respond_to_on_destroy runs.
  def destroy
    @signed_out = current_user.present?
    super
  end

  private

  def respond_with(resource, _opts = {})
    render json: {
      status: { code: 200, message: "Logged in sucessfully." },
      data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
    }, status: :ok
  end

  def respond_to_on_destroy(*)
    clear_jwt_cookie

    if @signed_out
      render json: {
        status: 200,
        message: "logged out successfully"
      }, status: :ok
    else
      render json: {
        status: 401,
        message: "Couldn't find an active session."
      }, status: :unauthorized
    end
  end
end
