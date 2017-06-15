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

    emp_id = params[:emp_id]

    if @emp_transaction.kind == "Onboarding"
      buddy_id = @emp_transaction.onboarding_infos.first.buddy_id
    end

    mgr_id = @emp_transaction.user_id
    @employee = Employee.find(emp_id)
    @manager = User.find(mgr_id)
    @buddy = Employee.find(buddy_id) if buddy_id
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

    set_machine_bundles

    @manager_entry = ManagerEntry.new
    @emp_transaction = @manager_entry.emp_transaction

    authorize! :new, @manager_entry.emp_transaction
  end

  # POST /emp_transactions
  # POST /emp_transactions.json
  def create
    @manager_entry = ManagerEntry.new(manager_entry_params)
    @emp_transaction = @manager_entry.emp_transaction
    emp_id = manager_entry_params[:employee_id]
    @employee = Employee.find emp_id if emp_id

    authorize! :create, @manager_entry.emp_transaction

    respond_to do |format|
      if @manager_entry.save
        format.html { redirect_to emp_transaction_path(@emp_transaction, emp_id: @employee.id), notice: 'Success! TechTable will be notified with the details of your request.' }
        format.json { render :show, status: :created, location: @emp_transaction }
        if @emp_transaction.kind != "Offboarding"
          TechTableMailer.permissions(@emp_transaction, @employee).deliver_now
        end
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

    def set_machine_bundles
      if @employee.worker_type.kind == "Regular"
        @machine_bundles = MachineBundle.find_bundles_for(@employee.department.id) - MachineBundle.contingent_bundles
      else
        @machine_bundles = MachineBundle.contingent_bundles
      end
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def manager_entry_params
      params.require(:manager_entry).permit(
        :kind,
        :user_id,
        :employee_id,
        :buddy_id,
        :cw_email,
        :cw_google_membership,
        :archive_data,
        :replacement_hired,
        :forward_email_id,
        :reassign_salesforce_id,
        :transfer_google_docs_id,
        :notes
      ).tap do |allowed|
        allowed[:security_profile_ids] = params[:security_profile_ids]
        allowed[:machine_bundle_id] = params[:machine_bundle_id]
      end
    end
end
