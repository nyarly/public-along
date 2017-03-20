class OffboardCommandsController < ApplicationController

  def index
    @offboard_command = OffboardCommand.new
    authorize! :index, @offboard_command
  end

  def new
    @offboard_command = OffboardCommand.new
    authorize! :new, @offboard_command
  end

  def create
    @offboard_command = OffboardCommand.new(offboard_command_params)
    authorize! :create, @offboard_command
    @offboard_command.employee

    respond_to do |format|
      if @offboard_command.valid?
        format.html { render :index, location: @offboard_command }
        format.json { render :index, status: :created, location: @offboard_command }
      else
        format.html { render :index }
        format.json { render json: @offboard_command.erros, status: :unprocessable_entity}
      end
    end
  end

  private

  def offboard_command_params
    params.require(:offboard_command).permit(:employee_id)
  end

end