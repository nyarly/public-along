class ApprovalsController < ApplicationController
  # load_and_authorize_resource

  def index; end

  def show; end

  def edit
    @approval_form = ApprovalForm.new(approval_id: params[:id])
  end

  def update
    approval = Approval.find(params[:id])
    @approval_form = ApprovalForm.new(approval_params)

    respond_to do |format|
      if @approval_form.save
        format.html { redirect_to @approval, notice: 'Approval processed successfully.' }
        format.json { render :show, status: :ok, location: @approval }
      else
        format.html { render :edit }
        format.json { render json: @approval.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def approval_params
    params.require(:approval_form).permit(
      :approval_decision,
      :notes,
      :user_id,
      :approver_designation_id,
      :emp_transaction_id,
      :request_emp_transaction_id,
      :status,
      :requested_at,
      :cancelled_at,
      :approved_at,
      :rejected_at,
      :executed_at
    )
  end
end
