require 'rails_helper'

describe TransactionProcesser, type: :service do
  describe '#call' do
    let(:sec_service)     { double(SecAccessService) }
    let(:onboard_service) { double(EmployeeService::Onboard) }

    before do
      allow(EmployeeService::Onboard).to receive(:new).and_return(onboard_service)
      allow(onboard_service).to receive(:new_worker)
      allow(onboard_service).to receive(:re_onboard)
      allow(SecAccessService).to receive(:new).and_return(sec_service)
      allow(sec_service).to receive(:apply_ad_permissions)
      allow(TechTableWorker).to receive(:perform_async)
    end

    context 'when offboard form' do
      subject(:process) { TransactionProcesser.new(transaction) }

      let(:employee) { FactoryGirl.create(:active_employee) }
      let(:transaction) do
        FactoryGirl.create(:emp_transaction,
          employee: employee,
          kind: 'Offboarding')
      end

      before do
        FactoryGirl.create(:offboarding_info, emp_transaction: transaction)
      end

      it 'returns true' do
        expect(process.call).to eq(true)
      end
    end

    context 'when onboard' do
      context 'when regular' do
        subject(:process) { TransactionProcesser.new(transaction) }

        let(:mailer)    { double(TechTableMailer) }
        let(:employee)  { FactoryGirl.create(:pending_employee) }
        let(:transaction) do
          FactoryGirl.create(:emp_transaction,
            employee: employee,
            kind: "Onboarding")
        end

        before do
          FactoryGirl.create(:onboarding_info, emp_transaction: transaction)

          process.call
        end

        it 'initiates security access service changes' do
          expect(SecAccessService).to have_received(:new).with(transaction)
          expect(sec_service).to have_received(:apply_ad_permissions)
        end

        it 'emails TechTable' do
          expect(TechTableWorker).to have_received(:perform_async).with(:onboard_instructions, transaction.id).once
        end
      end

      context 'when rehire' do
        context 'when worker has new record' do
          subject(:process) { TransactionProcesser.new(transaction) }

          let(:profile) do
            FactoryGirl.create(:profile,
              profile_status: 'pending',
              start_date: 1.week.from_now,
              employee_args: {
                hire_date: 1.year.ago,
                status: 'created'})
          end
          let(:transaction) do
            FactoryGirl.create(:emp_transaction,
              employee: profile.employee,
              kind: "Onboarding")
          end

          before do
            FactoryGirl.create(:onboarding_info, emp_transaction: transaction)

            process.call
          end

          it 'updates worker status' do
            expect(profile.employee.status).to eq('pending')
          end

          it 'initializes onboarding process' do
            expect(onboard_service).to have_received(:new_worker)
            expect(EmployeeService::Onboard).to have_received(:new).with(profile.employee)
          end

          it 'emails TechTable' do
            expect(TechTableWorker).to have_received(:perform_async).with(:onboard_instructions, transaction.id).once
          end
        end

        context 'when worker has linked accounts' do
          subject(:process) { TransactionProcesser.new(transaction) }

          let(:profile) { FactoryGirl.create(:profile,
            profile_status: 'pending',
            start_date: 1.week.from_now,
            employee_args: {
              hire_date: 1.year.ago,
              status: 'terminated'}) }
          let(:transaction) do
            FactoryGirl.create(:emp_transaction,
              employee: profile.employee,
              kind: "Onboarding")
          end

          before do
            FactoryGirl.create(:onboarding_info, emp_transaction: transaction)

            process.call
          end

          it 'updates worker status' do
            expect(profile.employee.status).to eq('pending')
          end

          it 'initializes onboarding process' do
            expect(onboard_service).to have_received(:re_onboard)
            expect(EmployeeService::Onboard).to have_received(:new).with(profile.employee)
          end

          it 'emails TechTable' do
            expect(TechTableWorker).to have_received(:perform_async).with(:onboard_instructions, transaction.id).once
          end
        end
      end

      context 'when conversion' do
        subject(:process) { TransactionProcesser.new(transaction) }

        let(:profile) do
          FactoryGirl.create(:profile,
            profile_status: 'active',
            start_date: 1.week.from_now,
            employee_args: {
              hire_date: 1.year.ago,
              status: 'active'})
        end
        let(:transaction) do
          FactoryGirl.create(:emp_transaction,
            employee: profile.employee,
            kind: "Onboarding")
        end

        before do
          FactoryGirl.create(:profile, employee: profile.employee, profile_status: 'pending')
          FactoryGirl.create(:onboarding_info, emp_transaction: transaction)

          process.call
        end

        it 'does not change worker status' do
          expect(profile.employee.status).to eq('active')
        end

        it 'initializes onboarding process' do
          expect(onboard_service).to have_received(:re_onboard)
          expect(EmployeeService::Onboard).to have_received(:new).with(profile.employee)
        end

        it 'emails TechTable' do
          expect(TechTableWorker).to have_received(:perform_async).with(:onboard_instructions, transaction.id).once
        end
      end
    end

    context 'when security access form' do
      subject(:process) { TransactionProcesser.new(transaction) }

      let(:employee) { FactoryGirl.create(:active_employee) }
      let(:transaction) do
        FactoryGirl.create(:emp_transaction,
          employee: employee,
          kind: 'Security Access')
      end

      before do
        process.call
      end

      it 'does not change worker status' do
        expect(employee.status).to eq('active')
      end

      it 'updates security profiles' do
        expect(SecAccessService).to have_received(:new).with(transaction)
        expect(sec_service).to have_received(:apply_ad_permissions)
      end

      it 'emails techtable' do
        expect(TechTableWorker).to have_received(:perform_async).with(:permissions, transaction.id).once
      end
    end
  end
end
