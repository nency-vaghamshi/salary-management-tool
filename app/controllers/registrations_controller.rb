class RegistrationsController < ApplicationController
  skip_before_action :authenticate_user!
  layout "sessions"

  def new
  end
end
