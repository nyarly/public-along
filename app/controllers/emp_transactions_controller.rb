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

    case @emp_transaction.kind
    when "Onboarding"
      emp_id = @emp_transaction.onboarding_infos.first.employee_id
      buddy_id = @emp_transaction.onboarding_infos.first.buddy_id
    when "Offboarding"
      emp_id = @emp_transaction.offboarding_infos.first.employee_id
    when "Equipment"
      emp_id = @emp_transaction.emp_mach_bundles.first.employee_id
    when "Security Access"
      emp_id = @emp_transaction.emp_sec_profiles.first.employee_id unless @emp_transaction.emp_sec_profiles.blank?
      emp_id = @emp_transaction.revoked_emp_sec_profiles.first.employee_id if emp_id.blank?
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
        format.html { redirect_to @emp_transaction, notice: 'Success! TechTable will be notified with the details of your request.' }
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
