class OffboardCommandsController < ApplicationController
  load_and_authorize_resource
  
  def index
    @offboard_command = OffboardCommand.new
    @employees = Employee.all
  end

  def show
  end

  def new
    @offboard_command = OffboardCommand.new
  end

  def create
    @offboard_command = OffboardCommand.new(offboard_command_params)

    respond_to do |format|
      if @offboard_command.valid?
        format.html { render :index, location: @offboard_command }
        format.json { render :show, status: :created, location: @offboard_command }
      else
        format.html { render :index }
        format.json { render json: @offboard_command.errors, status: :unprocessable_entity }
      end
    end

  end

  private

  def offboard_command_params
    params.require(:offboard_command).permit(:employee_id)
  end

end