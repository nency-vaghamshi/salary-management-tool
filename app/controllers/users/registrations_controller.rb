class Users::RegistrationsController < Devise::RegistrationsController
  respond_to :json
  layout "sessions", only: :new
  # JWT-authenticated JSON API: CSRF doesn't apply to header auth, and the cookie
  # used by the web UI is SameSite=Lax.
  skip_forgery_protection
  skip_before_action :authenticate_user!, raise: false
  before_action :configure_permitted_params

  # Devise would hand the form to respond_with, which renders JSON here.
  def new
    build_resource
  end

  def create
    super { |user| set_jwt_cookie(user) if user.persisted? }
  end

  private

  def configure_permitted_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :name ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :name ])
  end

  def respond_with(resource, _opts = {})
    if request.method == "POST" && resource.persisted?
      render json: {
        status: { code: 200, message: "Signed up sucessfully." },
        data: UserSerializer.new(resource).serializable_hash[:data][:attributes]
      }, status: :ok
    elsif request.method == "DELETE"
      render json: {
        status: { code: 200, message: "Account deleted successfully." }
      }, status: :ok
    else
      render json: {
        status: { code: 422, message: "User couldn't be created successfully. #{resource.errors.full_messages.to_sentence}" }
      }, status: :unprocessable_entity
    end
  end
end
