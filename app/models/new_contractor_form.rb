# Contractor creation form object
class NewContractorForm
  include Virtus.model

  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attribute :req_or_po_number, String
  attribute :legal_approver, String

  attribute :kind, String
  attribute :user_id, Integer
  attribute :notes, String

  attribute :first_name, String
  attribute :last_name, String
  attribute :hire_date, String
  attribute :contract_end_date, String
  attribute :business_title, String
  attribute :personal_mobile_phone, String
  attribute :personal_email, String
  attribute :manager_id, Integer

  attribute :business_unit_id, Integer
  attribute :location_id, Integer
  attribute :department_id, Integer
  attribute :start_date, String
  attribute :worker_type_id, Integer

  attr_accessor :emp_transaction
  attr_reader :employee

  def initialize(params)
    params.each do |key, value|
      instance_variable_set("@#{key}", value)
    end
  end

  def employee
    @employee ||= Employee.new(
      first_name: first_name,
      last_name: last_name,
      hire_date: start_date,
      contract_end_date: contract_end_date,
      personal_mobile_phone: personal_mobile_phone,
      personal_email: personal_email,
      manager_id: manager_id
      ).tap do |employee|
        employee.build_current_profile(
          business_title: business_title,
          location_id: location_id,
          department_id: department_id,
          job_title_id: contractor_job_title,
          worker_type_id: worker_type_id,
          business_unit_id: business_unit_id,
          start_date: start_date,
          end_date: contract_end_date
      )
    end
  end

  def emp_transaction
    @emp_transaction ||= EmpTransaction.new(
      kind: kind,
      user_id: user_id,
      notes: notes,
      employee_id: employee.id)
  end

  def contractor_job_title
    JobTitle.find_or_create_by(code: 'CONT', name: 'CONTRACTOR', status: 'Active').id
  end

  def contractor_info
    @contractor_info ||= emp_transaction.contractor_infos.build(
      req_or_po_number: req_or_po_number,
      legal_approver: legal_approver)
  end

  def save
    employee.save!
    contractor_info.save!
  end
end
