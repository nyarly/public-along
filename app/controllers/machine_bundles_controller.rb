class MachineBundlesController < ApplicationController
  load_and_authorize_resource

  before_action :set_machine_bundle, only: [:show, :edit, :update, :destroy]

  # GET /machine_bundles
  # GET /machine_bundles.json
  def index
    @machine_bundles = MachineBundle.all
  end

  # GET /machine_bundles/1
  # GET /machine_bundles/1.json
  def show
  end

  # GET /machine_bundles/new
  def new
    @machine_bundle = MachineBundle.new
  end

  # GET /machine_bundles/1/edit
  def edit
  end

  # POST /machine_bundles
  # POST /machine_bundles.json
  def create
    @machine_bundle = MachineBundle.new(machine_bundle_params)

    respond_to do |format|
      if @machine_bundle.save
        format.html { redirect_to @machine_bundle, notice: 'Machine bundle was successfully created.' }
        format.json { render :show, status: :created, location: @machine_bundle }
      else
        format.html { render :new }
        format.json { render json: @machine_bundle.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /machine_bundles/1
  # PATCH/PUT /machine_bundles/1.json
  def update
    respond_to do |format|
      if @machine_bundle.update(machine_bundle_params)
        format.html { redirect_to @machine_bundle, notice: 'Machine bundle was successfully updated.' }
        format.json { render :show, status: :ok, location: @machine_bundle }
      else
        format.html { render :edit }
        format.json { render json: @machine_bundle.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /machine_bundles/1
  # DELETE /machine_bundles/1.json
  def destroy
    @machine_bundle.destroy
    respond_to do |format|
      format.html { redirect_to machine_bundles_url, notice: 'Machine bundle was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_machine_bundle
      @machine_bundle = MachineBundle.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def machine_bundle_params
      params.require(:machine_bundle).permit(:name, :description)
    end
end
