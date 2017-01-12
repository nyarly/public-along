class ParentOrgsController < ApplicationController
  load_and_authorize_resource

  before_action :set_parent_org, only: [:show, :edit, :update, :destroy]

  # GET /parent_orgs
  # GET /parent_orgs.json
  def index
    @parent_orgs = ParentOrg.all
  end

  # GET /parent_orgs/1
  # GET /parent_orgs/1.json
  def show
  end

  # GET /parent_orgs/new
  def new
    @parent_org = ParentOrg.new
  end

  # GET /parent_orgs/1/edit
  def edit
  end

  # POST /parent_orgs
  # POST /parent_orgs.json
  def create
    @parent_org = ParentOrg.new(parent_org_params)

    respond_to do |format|
      if @parent_org.save
        format.html { redirect_to @parent_org, notice: 'Parent org was successfully created.' }
        format.json { render :show, status: :created, location: @parent_org }
      else
        format.html { render :new }
        format.json { render json: @parent_org.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /parent_orgs/1
  # PATCH/PUT /parent_orgs/1.json
  def update
    respond_to do |format|
      if @parent_org.update(parent_org_params)
        format.html { redirect_to @parent_org, notice: 'Parent org was successfully updated.' }
        format.json { render :show, status: :ok, location: @parent_org }
      else
        format.html { render :edit }
        format.json { render json: @parent_org.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /parent_orgs/1
  # DELETE /parent_orgs/1.json
  def destroy
    @parent_org.destroy
    respond_to do |format|
      format.html { redirect_to parent_orgs_url, notice: 'Parent org was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_parent_org
      @parent_org = ParentOrg.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def parent_org_params
      params.require(:parent_org).permit(:name, :code)
    end
end
