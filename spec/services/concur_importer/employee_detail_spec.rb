require 'rails_helper'

describe ConcurImporter::EmployeeDetail, type: :service do
  describe '.new' do
    let(:manager) { FactoryGirl.create(:manager) }

    context 'when manager' do
      subject(:detail) { ConcurImporter::EmployeeDetail.new(manager) }

      it 'is approver' do
        expect(detail.approver_status).to eq('Y')
      end
    end

    context 'without a manager' do
      subject(:detail) { ConcurImporter::EmployeeDetail.new(manager) }

      let(:worker) { FactoryGirl.create(:active_employee) }

      it 'does not have an approver assigned' do
        expect(detail.expense_report_approver).to eq(nil)
      end
    end

    context 'when terminated' do
      subject(:detail) { ConcurImporter::EmployeeDetail.new(termed_worker) }

      let(:termed_worker) { FactoryGirl.create(:terminated_employee) }

      it 'concur status is not active' do
        expect(detail.status).to eq('N')
      end
    end

    context 'when us office worker' do
      subject(:detail) { ConcurImporter::EmployeeDetail.new(us_position.employee) }

      let(:location) { FactoryGirl.create(:location, :sf) }
      let(:us_position) do
        FactoryGirl.create(:active_profile,
          location: location,
          company: 'OpenTable, Inc.',
          employee_args:
            {
              manager: manager,
              email: 'email',
              payroll_file_number: 'num',
              status: 'active'
            })
      end

      it 'has first name' do
        expect(detail.first_name).to eq(us_position.employee.first_name)
      end

      it 'has last name' do
        expect(detail.last_name).to eq(us_position.employee.last_name)
      end

      it 'has employee id' do
        expect(detail.employee_id).to eq(us_position.employee.employee_id)
      end

      it 'has email address' do
        expect(detail.email).to eq(us_position.employee.email)
      end

      it 'has US country code' do
        expect(detail.country_code).to eq('US')
      end

      it 'has active status' do
        expect(detail.status).to eq('Y')
      end

      it 'has company name' do
        expect(detail.company).to eq(us_position.company)
      end

      it 'has department code' do
        expect(detail.department_code).to eq(us_position.department.code)
      end

      it 'has location code' do
        expect(detail.location_code).to eq(us_position.location.code)
      end

      it 'group name is United States' do
        expect(detail.group_name_code).to eq('US')
      end

      it 'expense report approver is manager employee id' do
        expect(detail.expense_report_approver).to eq(manager.current_profile.adp_employee_id)
      end

      it 'cash advance approver is manager employee id' do
        expect(detail.cash_advance_approver).to eq(manager.current_profile.adp_employee_id)
      end

      it 'request approver is manager employee id' do
        expect(detail.request_approver).to eq(manager.current_profile.adp_employee_id)
      end

      it 'invoice approver is manager employee id' do
        expect(detail.invoice_approver).to eq(manager.current_profile.adp_employee_id)
      end

      it 'BI manager is manager employee id' do
        expect(detail.bi_manager).to eq(manager.current_profile.adp_employee_id)
      end

      it 'not approver' do
        expect(detail.approver_status).to eq('N')
      end

      it 'reimbursed by ADP' do
        expect(detail.reimbursement_method_code).to eq('ADPPAYR')
      end

      it 'uses file number' do
        expect(detail.adp_file_number).to eq('num')
      end

      it 'uses adp company code' do
        expect(detail.adp_company_code).to eq('WP8')
      end

      it 'uses adp deduction code' do
        expect(detail.adp_deduction_code).to eq('E')
      end
    end

    context 'when uk worker' do
      subject(:detail) { ConcurImporter::EmployeeDetail.new(uk_position.employee) }

      let(:location) { FactoryGirl.create(:location, :eu) }
      let(:uk_position) do
        FactoryGirl.create(:active_profile,
          location: location,
          company: 'OpenTable International, Inc.',
          employee_args:
            {
              manager: manager,
              email: 'email',
              payroll_file_number: 'num',
              status: 'active'
            })
      end

      it 'has the right location code' do
        expect(detail.location_code).to eq('LON')
      end

      it 'currency code is GBP' do
        expect(detail.currency_code).to eq('GBP')
      end

      it 'group name is United Kingdom' do
        expect(detail.group_name_code).to eq('UK')
      end

      it 'reimbursed by concur express pay' do
        expect(detail.reimbursement_method_code).to eq('CNQRPAY')
      end

      it 'does not use adp file number' do
        expect(detail.adp_file_number).to eq(nil)
      end
    end

    context 'when canadian worker' do
      subject(:detail) { ConcurImporter::EmployeeDetail.new(canadian.employee) }

      let(:canada) { FactoryGirl.create(:location, :can) }
      let(:canadian) do
        FactoryGirl.create(:active_profile,
          location: canada,
          company: 'OpenTable International, Inc.',
          employee_args:
            {
              email: 'email',
              payroll_file_number: 'num',
              status: 'active'
            })
      end

      it 'group name is Canada' do
        expect(detail.group_name_code).to eq('CA')
      end

      it 'reimbursed by check' do
        expect(detail.reimbursement_method_code).to eq('APCHECK')
      end

      it 'does not use file number' do
        expect(detail.adp_file_number).to eq(nil)
      end
    end

    context 'when other international worker' do
      subject(:detail) { ConcurImporter::EmployeeDetail.new(intl_position.employee) }

      let(:intl_location) { FactoryGirl.create(:location, :mex) }
      let(:intl_position) do
        FactoryGirl.create(:active_profile,
          location: intl_location,
          company: 'OpenTable International, Inc.',
          employee_args:
            {
              manager: manager,
              email: 'email',
              payroll_file_number: 'num',
              status: 'active'
            })
      end

      it 'reimbursed by concur express pay' do
        expect(detail.reimbursement_method_code).to eq('CNQRPAY')
      end

      it 'does not use adp file number' do
        expect(detail.adp_file_number).to eq(nil)
      end
    end
  end
end
