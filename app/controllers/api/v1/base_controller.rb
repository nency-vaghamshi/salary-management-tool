class Api::V1::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token, raise: false
  # The API skips CSRF checks, so it must only ever trust the explicit header.
  skip_before_action :use_cookie_token
  before_action :authenticate_user!

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: {
      error: "Resource not found",
      details: e.message
    }, status: :not_found
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: {
      error: "Validation failed",
      details: e.record.errors.full_messages
    }, status: :unprocessable_entity
  end
end
