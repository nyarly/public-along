class EmailsController < ApplicationController
  load_and_authorize_resource
  respond_to :json

  def new
    @email = Email.new
  end

  def create
    @email = Email.new(email_params)
    render json: @email

    respond_to do |format|
      if @email.valid?
        @email.send_email
        format.json { render 'form', status: :created, location: @email }
        flash.now[:notice] = "Got the stuff"
      end
    end
  end

  private

  def email_params
    params.require(:email).permit(:employee_id, :email_kind, :send_at)
  end

end