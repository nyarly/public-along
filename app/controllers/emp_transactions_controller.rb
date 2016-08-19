class EmpTransactionsController < ApplicationController
  load_and_authorize_resource

  before_action :set_emp_transaction, only: [:show, :edit, :update, :destroy]

  # GET /emp_transactions
  # GET /emp_transactions.json
  def index
    @emp_transactions = EmpTransaction.all
  end

  # GET /emp_transactions/1
  # GET /emp_transactions/1.json
  def show
    emp_id = @emp_transaction.emp_sec_profiles.first.employee_id
    mgr_id = @emp_transaction.user_id
    @employee = Employee.find(emp_id)
    @manager = User.find(mgr_id)
  end

  # GET /emp_transactions/new
  def new
    @emp_transaction = EmpTransaction.new
    @employee = Employee.find params[:employee_id]
    @kind = params[:kind]
    if params[:user_emp_id]
      @manager = User.find_by_employee_id params[:user_emp_id]
    elsif params[:user_id]
      @manager = User.find params[:user_id]
    end
    @emp_transaction.emp_sec_profiles.build
  end

  # GET /emp_transactions/1/edit
  def edit
  end

  # POST /emp_transactions
  # POST /emp_transactions.json
  def create
    @emp_transaction = EmpTransaction.new(emp_transaction_params)
    @sas = SecAccessService.new(@emp_transaction)

    respond_to do |format|
      if @sas.apply_ad_permissions
        format.html { redirect_to @emp_transaction, notice: 'Emp transaction was successfully created.' }
        format.json { render :show, status: :created, location: @emp_transaction }
      else
        format.html { redirect_to new_emp_transaction_path(manager_form_params) }
        format.json { render json: @emp_transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /emp_transactions/1
  # PATCH/PUT /emp_transactions/1.json
  def update
    respond_to do |format|
      if @emp_transaction.update(emp_transaction_params)
        format.html { redirect_to @emp_transaction, notice: 'Emp transaction was successfully updated.' }
        format.json { render :show, status: :ok, location: @emp_transaction }
      else
        format.html { render :edit }
        format.json { render json: @emp_transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /emp_transactions/1
  # DELETE /emp_transactions/1.json
  def destroy
    @emp_transaction.destroy
    respond_to do |format|
      format.html { redirect_to emp_transactions_url, notice: 'Emp transaction was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_emp_transaction
      @emp_transaction = EmpTransaction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def emp_transaction_params
      params.require(:emp_transaction).permit(
        :kind,
        :user_id,
        :emp_sec_profiles_attributes => [:id, :employee_id, :security_profile_id, :notes, :create])
    end

    def manager_form_params
      new_params = emp_transaction_params
      new_params[:employee_id] = emp_transaction_params["emp_sec_profiles_attributes"]["0"]["employee_id"]
      new_params
    end
end
