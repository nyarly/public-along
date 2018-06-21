class ApprovalsController < ApplicationController
  load_and_authorize_resource

  def index; end

  def show; end

  def edit
    @approval_form = ApprovalForm.new(approval_id: params[:id])
  end

  def update
    request_action = params[:commit]
    approval_id = params[:id]
    @approval_form = ApprovalForm.new(approval_params.merge(request_action: request_action, approval_id: approval_id))

    respond_to do |format|
      begin
        @approval_form.save
        format.html { redirect_to @approval, notice: 'Approval processed successfully.' }
        format.json { render :show, status: :ok, location: @approval }
      rescue StandardError => e
        flash[:notice] = e.message
        format.html { render :edit, notice: e.message }
        format.json { render json: @approval.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def approval_params
    params.require(:approval_form).permit(
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
