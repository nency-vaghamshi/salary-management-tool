class Api::V1::AuthController < Api::V1::BaseController
  skip_before_action :authenticate_user!, only: %i[signup login logout]

  def signup
    user = User.new(signup_params)

    if user.save
      render json: { token: issue_jwt_for(user), user: serialize(user) }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_content
    end
  end

  def login
    user = User.find_by(email: params[:email])

    if user&.valid_password?(params[:password])
      render json: { token: issue_jwt_for(user), user: serialize(user) }, status: :ok
    else
      render json: { error: "Invalid email or password" }, status: :unauthorized
    end
  end

  def logout
    cookies.delete(:jwt)
    head :no_content
  end

  def me
    render json: { user: serialize(current_user) }, status: :ok
  end

  private

  # Role is intentionally not permitted here: it must stay at its DB default
  # (hr_manager) so a signing-up client can't assign themselves a higher one.
  def signup_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  def serialize(user)
    { id: user.id, name: user.name, email: user.email }
  end

  def issue_jwt_for(user)
    token = JsonWebToken.encode({ user_id: user.id })
    cookies.signed[:jwt] = {
      value: token,
      httponly: true,
      same_site: :lax,
      expires: 24.hours.from_now
    }
    token
  end
end
