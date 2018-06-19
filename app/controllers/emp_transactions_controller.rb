class EmpTransactionsController < ApplicationController
  before_action :set_emp_transaction, only: [:show]

  def index
    authorize! :index, EmpTransaction

    @emp_transactions = EmpTransaction.all
  end

  def show
    authorize! :show, EmpTransaction
  end

  def new
    begin
      token = EmpTransaction.token
      session['submission_token'] = token

      @manager_entry = ManagerEntry.new(params.merge({ user_id: current_user.id }))
      @manager_entry.token = token

      authorize! :new, EmpTransaction
    rescue
      flash[:notice] = 'Invalid form.'
      redirect_to root_path
    end
  end

  def create
    begin
      if !double_submit?
        @manager_entry = ManagerEntry.new(manager_entry_params)
        @emp_transaction = @manager_entry.emp_transaction

        authorize! :create, @emp_transaction

        respond_to do |format|
          if @manager_entry.save
            Sessionable.new(session).change_token
            format.html { redirect_to emp_transaction_path(@emp_transaction), notice: 'Success! TechTable will be notified with the details of your request.' }
            format.json { render :show, status: :created, location: @emp_transaction }
          else
            format.html { redirect_to new_emp_transaction_path(manager_entry_params) }
            format.json { render json: @emp_transaction.errors, status: :unprocessable_entity }
          end
        end
      else
        if @emp_transaction.valid?
          respond_to do |format|
            format.html { redirect_to emp_transaction_path(@emp_transaction), notice: 'Success! TechTable will be notified with the details of your request.' }
            format.json { render :show, status: :created, location: @emp_transaction }
          end
        else
          respond_to do |format|
            format.html { redirect_to new_emp_transaction_path(manager_entry_params) }
            format.json { render json: @emp_transaction.errors, status: :unprocessable_entity }
          end
        end
      end
    rescue
      flash[:notice] = 'Invalid form.'
      redirect_to root_path
    end
  end

  private

  def double_submit?
    if (session[:submission_token].present?) && (session[:submission_token] == manager_entry_params[:submission_token])
      return false
    end
    true
  end

  def set_emp_transaction
    @emp_transaction = EmpTransaction.find(params[:id])
  end

  def manager_entry_params
    params.require(:manager_entry).permit(
      :submission_token,
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
      :link_email,
      :req_or_po_number,
      :legal_approver,
      :first_name,
      :last_name,
      :contract_end_date,
      :business_title,
      :personal_mobile_phone,
      :personal_email,
      :business_unit_id,
      :location_id,
      :start_date,
      :worker_type_id,
      :user_emp_id,
      :department_id,
      :manager_id
    ).tap do |allowed|
      allowed[:security_profile_ids] = params[:security_profile_ids]
      allowed[:machine_bundle_id] = params[:machine_bundle_id]
    end
  end
end

