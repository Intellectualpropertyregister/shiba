class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  before_filter :check_notifications
  # before_action :authenticate_user!
  # before_action :configure_permitted_parameters, if: :devise_controller?

  def configure_permitted_parameters
  	devise_parameter_sanitizer.for(:sign_up){ |u| u.permit(:nickname, :is_admin,:email,:password)}
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(resource_or_scope)
    '/login'
  end

  def check_notifications
      @app_notifications = Notification.where(reviewed: false)
  end
end
