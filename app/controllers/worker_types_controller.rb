class WorkerTypesController < ApplicationController
  load_and_authorize_resource

  before_action :set_worker_type, only: [:show, :edit, :update, :destroy]

  # GET /worker_types
  # GET /worker_types.json
  def index
    @worker_types = WorkerType.all
  end

  # GET /worker_types/1
  # GET /worker_types/1.json
  def show
  end

  # GET /worker_types/new
  def new
    @worker_type = WorkerType.new
  end

  # GET /worker_types/1/edit
  def edit
  end

  # POST /worker_types
  # POST /worker_types.json
  def create
    @worker_type = WorkerType.new(worker_type_params)

    respond_to do |format|
      if @worker_type.save
        format.html { redirect_to @worker_type, notice: 'Worker type was successfully created.' }
        format.json { render :show, status: :created, location: @worker_type }
      else
        format.html { render :new }
        format.json { render json: @worker_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /worker_types/1
  # PATCH/PUT /worker_types/1.json
  def update
    respond_to do |format|
      if @worker_type.update(worker_type_params)
        format.html { redirect_to @worker_type, notice: 'Worker type was successfully updated.' }
        format.json { render :show, status: :ok, location: @worker_type }
      else
        format.html { render :edit }
        format.json { render json: @worker_type.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /worker_types/1
  # DELETE /worker_types/1.json
  def destroy
    @worker_type.destroy
    respond_to do |format|
      format.html { redirect_to worker_types_url, notice: 'Worker type was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_worker_type
      @worker_type = WorkerType.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def worker_type_params
      params.require(:worker_type).permit(:name, :code, :kind, :status)
    end
end
