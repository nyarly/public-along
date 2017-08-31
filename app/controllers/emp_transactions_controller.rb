class EmpTransactionsController < ApplicationController

  before_action :set_emp_transaction, only: [:show]

  # autocomplete :employee, :email, :full => true, :extra_data => [:first_name, :last_name, :hire_date]

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

    @employee = @emp_transaction.employee

    if @emp_transaction.kind == "Onboarding"
      buddy_id = @emp_transaction.onboarding_infos.first.buddy_id
      @buddy = Employee.find(buddy_id) if buddy_id
    end
  end

  # GET /emp_transactions/new
  def new
    @kind = params[:kind]
    @reason = params[:reason]

    @manager_entry = ManagerEntry.new(params)
    @emp_transaction = @manager_entry.emp_transaction
    @employee = @manager_entry.find_employee

    if params[:event_id].present?
      @event = AdpEvent.find params[:event_id]
    end

    if params[:user_emp_id]
      @manager_user = User.find_by_employee_id params[:user_emp_id]
    elsif params[:user_id]
      @manager_user = User.find params[:user_id]
    end

    set_machine_bundles

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
        send_email
        format.html { redirect_to emp_transaction_path(@emp_transaction), notice: 'Success! TechTable will be notified with the details of your request.' }
        format.json { render :show, status: :created, location: @emp_transaction }
      else
        format.html { redirect_to new_emp_transaction_path(manager_entry_params) }
        format.json { render json: @emp_transaction.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def send_email
    if @emp_transaction.kind == "Onboarding"
      if @manager_entry.link_email == true
        TechTableMailer.onboard_instructions(@emp_transaction, link_email: true).deliver_now
      else
        TechTableMailer.onboard_instructions(@emp_transaction).deliver_now
      end
    else
      if @emp_transaction.kind != "Offboarding"
        TechTableMailer.permissions(@emp_transaction).deliver_now
      end
    end
  end

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
      :notes,
      :event_id,
      :linked_account_id,
      :link_email
    ).tap do |allowed|
      allowed[:security_profile_ids] = params[:security_profile_ids]
      allowed[:machine_bundle_id] = params[:machine_bundle_id]
    end
  end
end
