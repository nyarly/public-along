class EmpTransactionsController < ApplicationController

  before_action :set_emp_transaction, only: [:show]

  # GET /emp_transactions
  # GET /emp_transactions.json
  def index
    authorize! :index, EmpTransaction

    @emp_transactions = EmpTransaction.all
  end

  # GET /emp_transactions/1
  # GET /emp_transactions/1.json
  def show
    authorize! :show, EmpTransaction

    emp_id = @emp_transaction.emp_mach_bundles.first.employee_id
    mgr_id = @emp_transaction.user_id
    buddy_id = @emp_transaction.buddy_id
    @employee = Employee.find(emp_id)
    @manager = User.find(mgr_id)
    @buddy = Employee.find(buddy_id)
  end

  # GET /emp_transactions/new
  def new
    @kind = params[:kind]
    @employee = Employee.find params[:employee_id]
    if params[:user_emp_id]
      @manager_user = User.find_by_employee_id params[:user_emp_id]
    elsif params[:user_id]
      @manager_user = User.find params[:user_id]
    end

    @manager_entry = ManagerEntry.new
    @emp_transaction = @manager_entry.emp_transaction

    authorize! :new, @manager_entry.emp_transaction
  end

  # POST /emp_transactions
  # POST /emp_transactions.json
  def create
    @manager_entry = ManagerEntry.new(manager_entry_params)
    @emp_transaction = @manager_entry.emp_transaction

    authorize! :create, @manager_entry.emp_transaction

    respond_to do |format|
      if @manager_entry.save
        format.html { redirect_to @emp_transaction, notice: 'Emp transaction was successfully created.' }
        format.json { render :show, status: :created, location: @emp_transaction }
      else
        format.html { redirect_to new_emp_transaction_path(manager_entry_params) }
        format.json { render json: @emp_transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_emp_transaction
      @emp_transaction = EmpTransaction.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def manager_entry_params
      params.require(:manager_entry).permit(
        :kind,
        :user_id,
        :employee_id,
        :buddy_id,
        :notes
      ).tap do |allowed|
        allowed[:security_profile_ids] = params[:security_profile_ids]
        allowed[:machine_bundle_id] = params[:machine_bundle_id]
      end
    end
end
