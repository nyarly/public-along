class OffboardCommandsController < ApplicationController
  load_and_authorize_resource

  def generate
    if params[:employee_id]
      @offboard_command = OffboardCommand.new(params[:employee_id])
    end
  end
end
