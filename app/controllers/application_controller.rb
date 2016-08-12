class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_filter :store_current_location, :unless => :devise_controller?

  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def configure_permitted_parameters
    # devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:ldap_user, :password) }
    # devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  protected

  def store_current_location
    store_location_for(:user, request.url)
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end

  rescue_from CanCan::AccessDenied do |exception|
    if !user_signed_in?
      redirect_to login_path, :notice => "You are logged out."
    else
      if request.env["HTTP_REFERER"].present?
        redirect_to :back, :alert => "You do not have the correct access permissions."
      else
        redirect_to root_path, :alert => "You do not have the correct access permissions."
      end
    end
  end
end
