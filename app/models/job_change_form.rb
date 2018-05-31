class JobChangeForm
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations
  include ActiveModel::Model

  attr_accessor :emp_transaction
  attr_reader :employee
  attr_reader :event

  attribute :event_id, Integer
  attribute :link_email, String
  attribute :linked_account_id, Integer
  attribute :buddy_id, Integer
  attribute :cw_email, Boolean
  attribute :cw_google_membership, Boolean

  def initialize(params)
    self.extend(Virtus.model)

    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end

    raise 'Form Error' if event_id.blank?
  end

  def employee
    if link_accounts?
      @employee ||= link_worker
    elsif needs_new_account?
      @employee ||= new_worker
    else
      @employee ||= profile_builder.build_employee(event)
    end
  end

  def onboarding_info
    emp_transaction.onboarding_infos.build(
      buddy_id: buddy_id,
      cw_email: cw_email,
      cw_google_membership: cw_google_membership
    )
  end

  def event
    @event ||= AdpEvent.find(event_id)
  end

  def save
    onboarding_info.save!
    employee.complete!
    event.process!
  end

  private

  def profile_builder
    @profile_builder ||= EmployeeProfile.new
  end

  def link_worker
    profile_builder.link_accounts(linked_account_id, event_id)
  end

  def link_accounts?
    link_email == 'on' && linked_account_id.present?
  end

  def needs_new_account?
    link_email == 'off'
  end

  def new_worker
    profile_builder.new_employee(event)
  end
end
