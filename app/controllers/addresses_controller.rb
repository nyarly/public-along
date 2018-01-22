class AddressesController < ApplicationController
  load_and_authorize_resource

  def new
    @context = context
    @address = @context.addresses.new
  end

  def edit
    @context = context
    @address = @context.addresses.find(params[:id])
  end

  def create
    @context = context
    @address = @context.addresses.new(address_params)

    respond_to do |format|
      if @address.save
        format.html { redirect_to context_url(context), notice: 'Address was successfully created.' }
        format.json { render :show, status: :created, location: @address }
      else
        format.html { render :new }
        format.json { render json: @address.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    @context = context
    @address = @context.addresses.find(params[:id])

    respond_to do |format|
      if @address.update_attributes(address_params)
        format.html { redirect_to context_url(context), notice: 'Address was successfully updated.' }
        format.json { render json: @address.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def address_params
    params.require(:address).permit(
      :line_1,
      :line_2,
      :line_3,
      :city,
      :state_territory,
      :postal_code,
      :country_id
    )
  end

  def context
    if params[:employee_id].present?
      id = params[:employee_id]
      Employee.find(params(:employee_id))
    else
      id = params[:location_id]
      Location.find(params(:location_id))
    end
  end

  def context_url(context)
    if Employee == context
      employee_path(context)
    else
      location_path(context)
    end
  end
end
