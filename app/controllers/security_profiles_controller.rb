class SecurityProfilesController < ApplicationController
  load_and_authorize_resource

  before_action :set_security_profile, only: [:show, :edit, :update, :destroy]

  # GET /security_profiles
  # GET /security_profiles.json
  def index
    @security_profiles = SecurityProfile.all
  end

  # GET /security_profiles/1
  # GET /security_profiles/1.json
  def show
  end

  # GET /security_profiles/new
  def new
    @security_profile_entry = SecurityProfileEntry.new
    @security_profile = @security_profile_entry.security_profile
    @access_level = AccessLevel.new
  end

  # GET /security_profiles/1/edit
  def edit
    @security_profile_entry = SecurityProfileEntry.new("id" => params[:id])
    @security_profile = @security_profile_entry.security_profile
  end

  # POST /security_profiles
  # POST /security_profiles.json
  def create
    @security_profile_entry = SecurityProfileEntry.new(security_profile_entry_params)
    @security_profile = @security_profile_entry.security_profile

    respond_to do |format|
      if @security_profile.save
        format.html { redirect_to @security_profile, notice: 'Security profile was successfully created.' }
        format.json { render :show, status: :created, location: @security_profile }
      else
        format.html { render :new }
        format.json { render json: @security_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /security_profiles/1
  # PATCH/PUT /security_profiles/1.json
  def update
    @security_profile_entry = SecurityProfileEntry.new(security_profile_entry_params.merge("id" => params[:id]))
    @security_profile = @security_profile_entry.security_profile

    respond_to do |format|
      if @security_profile.update(security_profile_entry_params)
        format.html { redirect_to @security_profile, notice: 'Security profile was successfully updated.' }
        format.json { render :show, status: :ok, location: @security_profile }
      else
        format.html { render :edit }
        format.json { render json: @security_profile.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /security_profiles/1
  # DELETE /security_profiles/1.json
  def destroy
    @security_profile.destroy
    respond_to do |format|
      format.html { redirect_to security_profiles_url, notice: 'Security profile was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def persisted?
    @security_profile.nil? ? false : @security_profile.persisted?
  end


  private
    # Use callbacks to share common setup or constraints between actions.
    def set_security_profile
      @security_profile = SecurityProfile.find(params[:id])
    end

    def security_profile_entry_params
      params.require(:security_profile_entry).permit(:name, :description, department_ids: [], access_level_ids: [])
    end

end
