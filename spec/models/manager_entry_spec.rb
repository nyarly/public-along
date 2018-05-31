require 'rails_helper'

RSpec.describe ManagerEntry do
  let!(:manager_sec_prof) { FactoryGirl.create(:security_profile,
                            name: 'Basic Manager') }
  let(:buddy)             { FactoryGirl.create(:active_employee) }
  let(:user)              { FactoryGirl.create(:user) }
  let(:sp_1)              { FactoryGirl.create(:security_profile) }
  let(:sp_2)              { FactoryGirl.create(:security_profile) }
  let(:sp_3)              { FactoryGirl.create(:security_profile) }
  let(:sp_4)              { FactoryGirl.create(:security_profile) }
  let(:machine_bundle)    { FactoryGirl.create(:machine_bundle) }

  describe '#save' do
    context 'Onboard' do
      context 'New Hire' do
        let(:employee) { FactoryGirl.create(:pending_employee,
                         request_status: 'waiting') }

        context 'with valid params' do
          let(:params) do
            {
              kind: 'onboarding',
              user_id: user.id,
              buddy_id: buddy.id,
              cw_email: 1,
              cw_google_membership: 0,
              notes: 'These notes',
              employee_id: employee.id,
              security_profile_ids: [sp_1.id, sp_2.id, sp_3.id],
              machine_bundle_id: machine_bundle.id
            }
          end
          let(:manager_entry) { ManagerEntry.new(params) }

          before do
            manager_entry.save
          end

          it 'creates an emp_transaction with the right attrs' do
            expect(manager_entry.emp_transaction.kind).to eq('onboarding')
            expect(manager_entry.emp_transaction.user_id).to eq(user.id)
            expect(manager_entry.emp_transaction.notes).to eq('These notes')
            expect(manager_entry.emp_transaction.employee_id).to eq(employee.id)
          end

          it 'creates onboarding info' do
            expect(manager_entry.emp_transaction.onboarding_infos.count).to eq(1)
            expect(manager_entry.emp_transaction.onboarding_infos.first.buddy_id).to eq(buddy.id)
            expect(manager_entry.emp_transaction.onboarding_infos.first.cw_email).to eq(true)
            expect(manager_entry.emp_transaction.onboarding_infos.first.cw_google_membership).to eq(false)
          end

          it 'creates employee security profiles' do
            expect(manager_entry.emp_transaction.security_profiles.count).to eq(3)
            expect(manager_entry.emp_transaction.emp_sec_profiles.first.security_profile_id).to eq(sp_1.id)
          end

          it 'builds machine bundles' do
            expect(manager_entry.emp_transaction.machine_bundles.count).to eq(1)
            expect(manager_entry.emp_transaction.employee_id).to eq(employee.id)
            expect(employee.emp_mach_bundles.count).to eq(1)
            expect(employee.emp_mach_bundles[0].machine_bundle).to eq(machine_bundle)
          end

          it 'updates request status' do
            expect(employee.reload.request_status).to eq('completed')
          end
        end

        context 'with non-existant form type' do
          let(:params) do
            {
              kind: 'hackery',
              user_id: user.id,
              buddy_id: buddy.id,
              cw_email: 1,
              cw_google_membership: 0,
              notes: 'These notes',
              employee_id: nil,
              security_profile_ids: [sp_1.id, sp_2.id, sp_3.id],
              machine_bundle_id: machine_bundle.id,
              event_id: nil
            }
          end

          it 'reports errors' do
            expect {
              ManagerEntry.new(params)
            }.to raise_error(KeyError)
          end
        end
      end

      context 'Worker Type Change' do
        let(:manager)           { FactoryGirl.create(:employee) }
        let!(:manager_profile)  { FactoryGirl.create(:profile,
                                  employee: manager,
                                  adp_employee_id: '101836') }
        let!(:worker_type)      { FactoryGirl.create(:worker_type,
                                  code: 'ACW',
                                  name: 'Contractor') }
        let(:active_employee)   { FactoryGirl.create(:active_employee,
                                  request_status: 'none') }
        let(:hire_event)        { File.read(Rails.root.to_s + '/spec/fixtures/adp_cat_change_hire_event.json') }
        let(:event)             { FactoryGirl.create(:adp_event,
                                  status: 'new',
                                  json: hire_event) }
        let(:sp_1)              { FactoryGirl.create(:security_profile,
                                  name: 'Basic Regular Worker Profile') }
        let(:sp_2)              { FactoryGirl.create(:security_profile,
                                  name: 'Basic Temp Worker Profile') }
        let(:sp_3)              { FactoryGirl.create(:security_profile,
                                  name: 'Basic Contract Worker Profile') }
        let(:machine_bundle)    { FactoryGirl.create(:machine_bundle) }

        context 'when accounts are linked by manager' do
          let(:link_on_params) do
            {
              kind: 'job_change',
              event_id: event.id,
              user_id: user.id,
              buddy_id: nil,
              cw_email: 1,
              cw_google_membership: 0,
              notes: 'These notes',
              security_profile_ids: [sp_1.id, sp_2.id, sp_3.id],
              machine_bundle_id: machine_bundle.id,
              link_email: 'on',
              linked_account_id: active_employee.id
            }
          end
          let(:manager_entry) { ManagerEntry.new(link_on_params) }

          before :each do
            manager_entry.save
          end

          it 'uses an existing employee' do
            expect(manager_entry.emp_transaction.employee).to eq(active_employee)
          end

          it 'creates a new profile' do
            expect(active_employee.profiles.count).to eq(2)
          end

          it 'has an active profile' do
            expect(active_employee.profiles.active.count).to eq(1)
          end

          it 'has a pending profile' do
            expect(active_employee.profiles.pending.count).to eq(1)
          end

          it 'has the right profile set as pending' do
            expect(active_employee.profiles.pending.last.worker_type).to eq(worker_type)
          end

          it 'does not update the employee status' do
            active_employee.reload
            expect(active_employee.status).to eq('active')
          end

          it 'creates an emp_transaction with the right attrs' do
            expect(manager_entry.emp_transaction.kind).to eq('job_change')
            expect(manager_entry.emp_transaction.user_id).to eq(user.id)
            expect(manager_entry.emp_transaction.notes).to eq('These notes')
            expect(manager_entry.emp_transaction.employee_id).to eq(active_employee.id)
          end

          it 'creates onboarding info' do
            expect(manager_entry.emp_transaction.onboarding_infos.count).to eq(1)
            expect(manager_entry.emp_transaction.onboarding_infos.first.buddy_id).to eq(nil)
            expect(manager_entry.emp_transaction.onboarding_infos.first.cw_email).to eq(true)
            expect(manager_entry.emp_transaction.onboarding_infos.first.cw_google_membership).to eq(false)
          end

          it 'creates employee security profiles' do
            expect(manager_entry.emp_transaction.security_profiles.count).to eq(3)
            expect(manager_entry.emp_transaction.emp_sec_profiles.first.security_profile_id).to eq(sp_1.id)
          end

          it 'builds machine bundles' do
            expect(manager_entry.emp_transaction.machine_bundles.count).to eq(1)
            expect(manager_entry.emp_transaction.employee_id).to eq(active_employee.id)
            expect(active_employee.emp_mach_bundles.count).to eq(1)
            expect(active_employee.emp_mach_bundles[0].machine_bundle).to eq(machine_bundle)
          end

          it 'updates the request status' do
            active_employee.reload
            expect(active_employee.request_status).to eq('completed')
          end

          it 'updates event status' do
            event.reload
            expect(event.status).to eq('processed')
          end
        end
      end

      context 'Rehire' do
        let(:manager)           { FactoryGirl.create(:employee) }
        let!(:manager_profile)  { FactoryGirl.create(:profile,
                                  employee: manager,
                                  adp_employee_id: '654321') }
        let!(:worker_type)      { FactoryGirl.create(:worker_type,
                                  code: 'FTR',
                                  name: 'Regular Full-Time') }
        let(:old_employee)      { FactoryGirl.create(:terminated_employee,
                                  hire_date: Date.new(2016, 1, 1),
                                  termination_date: Date.new(2016, 2, 2)) }
        let(:rehire_event)      { File.read(Rails.root.to_s + '/spec/fixtures/adp_rehire_event.json') }
        let(:event)             { FactoryGirl.create(:adp_event,
                                  status: 'new',
                                  json: rehire_event) }

        context 'when accounts are linked by manager' do
          let(:link_on_params) do
            {
              kind: 'job_change',
              event_id: event.id,
              user_id: user.id,
              buddy_id: nil,
              cw_email: 1,
              cw_google_membership: 0,
              notes: 'These notes',
              security_profile_ids: [sp_1.id, sp_2.id, sp_3.id],
              machine_bundle_id: machine_bundle.id,
              link_email: 'on',
              linked_account_id: old_employee.id
            }
          end
          let(:manager_entry) { ManagerEntry.new(link_on_params) }

          before :each do
            manager_entry.save
            old_employee.reload
          end

          it 'uses an existing employee' do
            expect(manager_entry.emp_transaction.employee).to eq(old_employee)
          end

          it 'creates a new profile' do
            expect(old_employee.profiles.count).to eq(2)
          end

          it 'has a terminated profile' do
            expect(old_employee.profiles.terminated.count).to eq(1)
          end

          it 'has the right manager' do
            expect(old_employee.manager).to eq(manager)
          end

          it 'has a pending profile' do
            expect(old_employee.profiles.pending.count).to eq(1)
          end

          it 'has the right profile set as pending' do
            expect(old_employee.profiles.pending.last.worker_type).to eq(worker_type)
          end

          it 'has the original hire date' do
            expect(old_employee.hire_date).to eq(Date.new(2016, 1, 1))
          end

          it 'has no termination date' do
            expect(old_employee.termination_date).to eq(nil)
          end

          it 'has correct start date for new position' do
            expect(old_employee.profiles.pending.last.start_date).to eq(DateTime.new(2018, 9, 1))
          end

          it 'does not update the employee status' do
            expect(old_employee.reload.status).to eq('pending')
          end

          it 'creates an emp_transaction with the right attrs' do
            expect(manager_entry.emp_transaction.kind).to eq('job_change')
            expect(manager_entry.emp_transaction.user_id).to eq(user.id)
            expect(manager_entry.emp_transaction.notes).to eq('These notes')
            expect(manager_entry.emp_transaction.employee_id).to eq(old_employee.id)
          end

          it 'creates onboarding info' do
            expect(manager_entry.emp_transaction.onboarding_infos.count).to eq(1)
            expect(manager_entry.emp_transaction.onboarding_infos.first.buddy_id).to eq(nil)
            expect(manager_entry.emp_transaction.onboarding_infos.first.cw_email).to eq(true)
            expect(manager_entry.emp_transaction.onboarding_infos.first.cw_google_membership).to eq(false)
          end

          it 'creates employee security profiles' do
            expect(manager_entry.emp_transaction.security_profiles.count).to eq(3)
            expect(manager_entry.emp_transaction.emp_sec_profiles.first.security_profile_id).to eq(sp_1.id)
          end

          it 'builds machine bundles' do
            expect(manager_entry.emp_transaction.machine_bundles.count).to eq(1)
            expect(manager_entry.emp_transaction.employee_id).to eq(old_employee.id)
            expect(old_employee.emp_mach_bundles.count).to eq(1)
            expect(old_employee.emp_mach_bundles[0].machine_bundle).to eq(machine_bundle)
          end

          it 'updates the request status' do
            expect(old_employee.request_status).to eq('completed')
          end

          it 'updates event status' do
            event.reload
            expect(event.status).to eq('processed')
          end
        end

        context 'when accounts are not linked by manager' do
          let(:link_off_params) do
            {
              kind: 'job_change',
              event_id: event.id,
              user_id: user.id,
              buddy_id: nil,
              cw_email: 1,
              cw_google_membership: 0,
              notes: 'These notes',
              security_profile_ids: [sp_1.id, sp_2.id, sp_3.id],
              machine_bundle_id: machine_bundle.id,
              link_email: 'off'
            }
          end
          let(:manager_entry) { ManagerEntry.new(link_off_params) }
          let(:employee) { Employee.find_by(last_name: "Fakename") }

          it 'increases employee count by 1' do
            expect{
              manager_entry.save
            }.to change{ Employee.count }.by(1)
          end

          it 'creates a pending employee' do
            manager_entry.save

            expect(employee.status).to eq('pending')
          end

          it 'gives pending employee one profile' do
            manager_entry.save

            expect(employee.profiles.count).to eq(1)
          end

          it 'creates an emp_transaction with the right attrs' do
            manager_entry.save

            expect(manager_entry.emp_transaction.kind).to eq('job_change')
            expect(manager_entry.emp_transaction.user_id).to eq(user.id)
            expect(manager_entry.emp_transaction.notes).to eq('These notes')
            expect(manager_entry.emp_transaction.employee_id).to eq(employee.id)
          end

          it 'creates onboarding info' do
            manager_entry.save

            expect(manager_entry.emp_transaction.onboarding_infos.count).to eq(1)
            expect(manager_entry.emp_transaction.onboarding_infos.first.buddy_id).to eq(nil)
            expect(manager_entry.emp_transaction.onboarding_infos.first.cw_email).to eq(true)
            expect(manager_entry.emp_transaction.onboarding_infos.first.cw_google_membership).to eq(false)
          end

          it 'creates employee security profiles' do
            manager_entry.save

            expect(manager_entry.emp_transaction.security_profiles.count).to eq(3)
            expect(manager_entry.emp_transaction.emp_sec_profiles.first.security_profile_id).to eq(sp_1.id)
          end

          it 'builds machine bundles' do
            manager_entry.save

            expect(manager_entry.emp_transaction.machine_bundles.count).to eq(1)
            expect(manager_entry.emp_transaction.employee_id).to eq(employee.id)
            expect(employee.emp_mach_bundles.count).to eq(1)
            expect(employee.emp_mach_bundles[0].machine_bundle).to eq(machine_bundle)
          end

          it 'updates the request status' do
            manager_entry.save

            employee.reload
            expect(employee.request_status).to eq('completed')
          end

          it 'updates event status' do
            manager_entry.save

            event.reload
            expect(event.status).to eq('processed')
          end
        end
      end
    end

    context 'Security Access Change' do
      let(:employee)  { FactoryGirl.create(:active_employee) }
      let!(:et_1)     { FactoryGirl.create(:emp_transaction,
                        employee_id: employee.id) }
      let!(:esp_1)    { FactoryGirl.create(:emp_sec_profile,
                        emp_transaction_id: et_1.id,
                        security_profile_id: sp_1.id,
                        revoking_transaction_id: nil) }
      let!(:esp_2)    { FactoryGirl.create(:emp_sec_profile,
                        emp_transaction_id: et_1.id,
                        security_profile_id: sp_2.id,
                        revoking_transaction_id: nil) }
      let!(:esp_3)    { FactoryGirl.create(:emp_sec_profile,
                        emp_transaction_id: et_1.id,
                        security_profile_id: sp_3.id,
                        revoking_transaction_id: nil) }
      let(:params) do
        {
          kind: 'security_access',
          user_id: user.id,
          employee_id: employee.id,
          security_profile_ids: [sp_1.id, sp_3.id, sp_4.id]
        }
      end
      let(:manager_entry) { ManagerEntry.new(params) }

      it 'creates emp transaction' do
        expect{
          manager_entry.save
        }.to change{
          employee.emp_transactions.count
        }.by(1)
      end

      it 'adds and revokes specified security profiles' do
        manager_entry.save

        expect(employee.reload.security_profiles.pluck(:id).sort).to eq([sp_1.id, sp_2.id, sp_3.id, sp_4.id])
        expect(employee.reload.active_security_profiles.pluck(:id).sort).to eq([sp_1.id, sp_3.id, sp_4.id])
        expect(employee.reload.revoked_security_profiles.pluck(:id).sort).to eq([sp_2.id])
        expect(esp_1.reload.revoking_transaction_id).to be_nil
        expect(esp_2.reload.revoking_transaction_id).to_not be_nil
        expect(esp_3.reload.revoking_transaction_id).to be_nil
      end

      it 'has correct request status' do
        expect(employee.request_status).to eq('none')
      end
    end

    context 'offboarding' do
      let(:forward)           { FactoryGirl.create(:employee) }
      let!(:employee)         { FactoryGirl.create(:active_employee,
                                request_status: 'waiting') }
      let!(:security_profile) { FactoryGirl.create(:security_profile) }
      let!(:emp_sec_profile)  { FactoryGirl.create(:emp_sec_profile,
                                security_profile_id: security_profile.id) }
      let(:params) do
        {
          kind: 'offboarding',
          user_id: user.id,
          employee_id: employee.id,
          archive_data: true,
          replacement_hired: false,
          forward_email_id: forward.id,
          reassign_salesforce_id: forward.id,
          transfer_google_docs_id: forward.id,
          notes: 'stuff'
        }
      end
      let(:manager_entry) { ManagerEntry.new(params) }

      it 'creates emp transaction' do
        expect{
          manager_entry.save
        }.to change{
          employee.emp_transactions.count
        }.by(1)
      end

      it 'creates offboarding info' do
        manager_entry.save

        expect(manager_entry.emp_transaction.offboarding_infos.count).to eq(1)
        expect(manager_entry.emp_transaction.offboarding_infos.first.archive_data).to eq(true)
        expect(manager_entry.emp_transaction.offboarding_infos.first.replacement_hired).to eq(false)
        expect(manager_entry.emp_transaction.offboarding_infos.first.forward_email_id).to eq(forward.id)
        expect(manager_entry.emp_transaction.offboarding_infos.first.reassign_salesforce_id).to eq(forward.id)
        expect(manager_entry.emp_transaction.offboarding_infos.first.transfer_google_docs_id).to eq(forward.id)
        expect(manager_entry.emp_transaction.notes).to eq('stuff')
      end

      it 'has correct request status' do
        expect{
          manager_entry.save
        }.to change{
          employee.reload.request_status
        }.from('waiting').to('completed')
      end
    end

    context 'when new_contractor kind' do
      subject(:contractor_entry) { NewContractorForm.new(params) }

      let!(:employee)     { FactoryGirl.create(:regular_employee) }
      let(:user)          { FactoryGirl.create(:user, employee: employee) }
      let!(:department)   { FactoryGirl.create(:department) }
      let!(:location)     { FactoryGirl.create(:location) }
      let!(:biz_unit)     { FactoryGirl.create(:business_unit) }
      let!(:worker_type)  { FactoryGirl.create(:worker_type, kind: 'Contractor') }

      let(:params) do
        {
          user_id: user.id,
          notes: 'some notes',
          req_or_po_number: '1234',
          legal_approver: 'fname lname',
          first_name: 'contractorfname',
          last_name: 'contractorlname',
          start_date: Date.new(2018, 7, 1),
          contract_end_date: Date.new(2018, 12, 31),
          business_title: 'a title',
          personal_mobile_phone: '888-888-8888',
          personal_email: 'email@example.com',
          manager_id: employee.id,
          business_unit_id: biz_unit.id,
          location_id: location.id,
          department_id: department.id,
          worker_type_id: worker_type.id,
          kind: 'new_contractor'
        }
      end

      it 'creates one emp transaction' do
        expect {
          contractor_entry.save
        }.to change { EmpTransaction.count }.by(1)
      end

      it 'creates an emp transaction with the right info' do
        contractor_entry.save
        expect(contractor_entry.emp_transaction.user).to eq(user)
        expect(contractor_entry.emp_transaction.kind).to eq('new_contractor')
        expect(contractor_entry.emp_transaction.notes).to eq('some notes')
      end

      it 'creates one contractor info' do
        expect {
          contractor_entry.save
        }.to change { ContractorInfo.count }.by(1)
      end

      it 'creates a contractor info with the right info' do
        contractor_entry.save
        expect(contractor_entry.contractor_info.req_or_po_number).to eq('1234')
        expect(contractor_entry.contractor_info.legal_approver).to eq('fname lname')
      end

      it 'creates one employee record' do
        expect {
          contractor_entry.save
        }.to change { Employee.count }.by(1)
      end

      it 'creates a new employee with the right info' do
        contractor_entry.save
        expect(contractor_entry.employee.status).to eq('created')
        expect(contractor_entry.employee.first_name).to eq('contractorfname')
        expect(contractor_entry.employee.last_name).to eq('contractorlname')
        expect(contractor_entry.employee.hire_date).to eq(Date.new(2018, 7, 1))
        expect(contractor_entry.employee.contract_end_date).to eq(Date.new(2018, 12, 31))
        expect(contractor_entry.employee.personal_mobile_phone).to eq('888-888-8888')
        expect(contractor_entry.employee.personal_email).to eq('email@example.com')
        expect(contractor_entry.employee.manager_id).to eq(employee.id)
      end

      it 'creates one new profile' do
        expect {
          contractor_entry.save
        }.to change { Profile.count }.by(1)
      end

      it 'creates a profile with the right info' do
        contractor_entry.save
        expect(contractor_entry.employee.current_profile.profile_status).to eq('pending')
        expect(contractor_entry.employee.profiles.count).to eq(1)
        expect(contractor_entry.employee.current_profile.business_title).to eq('a title')
        expect(contractor_entry.employee.current_profile.location).to eq(location)
        expect(contractor_entry.employee.current_profile.department).to eq(department)
        expect(contractor_entry.employee.current_profile.job_title.name).to eq('CONTRACTOR')
        expect(contractor_entry.employee.current_profile.worker_type).to eq(worker_type)
        expect(contractor_entry.employee.current_profile.business_unit).to eq(biz_unit)
        expect(contractor_entry.employee.current_profile.start_date).to eq(Date.new(2018, 7, 1))
        expect(contractor_entry.employee.current_profile.end_date).to eq(Date.new(2018, 12, 31))
      end
    end
  end
end
