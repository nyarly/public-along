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

        let(:employee) { FactoryGirl.create(:pending_employee) }
        let(:transaction) do
          FactoryGirl.create(:emp_transaction,
            employee: employee,
            kind: "Onboarding")
        end
        let(:mailer) { double(TechTableMailer) }

        before do
          FactoryGirl.create(:onboarding_info, emp_transaction: transaction)
          allow(TechTableMailer).to receive(:onboard_instructions).and_return(mailer)
          allow(mailer).to receive(:deliver_now)
        end

        it 'initiates security access service changes' do
          expect(SecAccessService).to receive(:new).and_return(sec_service)
          expect(sec_service).to receive(:apply_ad_permissions)
          process.call
        end

        it 'emails TechTable' do
          expect(TechTableMailer).to receive(:onboard_instructions).once
          # expect(TechTableWorker).to receive(:perform_async).with(:onboard_instructions, transaction.id).once
          process.call
        end
      end

      context 'when rehire' do
        context 'when worker has new record' do
          subject(:process) { TransactionProcesser.new(transaction) }

          let(:profile) { FactoryGirl.create(:profile,
            profile_status: 'pending',
            start_date: 1.week.from_now,
            employee_args: {
              hire_date: 1.year.ago,
              status: 'created'}) }
          let(:transaction) do
            FactoryGirl.create(:emp_transaction,
              employee: profile.employee,
              kind: "Onboarding")
          end

          before do
            FactoryGirl.create(:onboarding_info, emp_transaction: transaction)
          end

          it 'updates worker status' do
            process.call
            expect(profile.employee.status).to eq('pending')
          end

          it 'initializes onboarding process' do
            expect(onboard_service).to receive(:new_worker)
            expect(EmployeeService::Onboard).to receive(:new).with(profile.employee).and_return(onboard_service)
            process.call
          end

          it 'emails TechTable' do
            expect(TechTableWorker).to receive(:perform_async).with(:onboard_instructions, transaction).once
            process.call
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
          end

          it 'updates worker status' do
            process.call
            expect(profile.employee.status).to eq('pending')
          end

          it 'initializes onboarding process' do
            expect(onboard_service).to receive(:re_onboard)
            expect(EmployeeService::Onboard).to receive(:new).with(profile.employee).and_return(onboard_service)
            process.call
          end

          it 'emails TechTable' do
            expect(TechTableWorker).to receive(:perform_async).with(:onboard_instructions, transaction).once
            process.call
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
        end

        it 'does not change worker status' do
          process.call
          expect(profile.employee.status).to eq('active')
        end

        it 'initializes onboarding process' do
          expect(onboard_service).to receive(:re_onboard)
          expect(EmployeeService::Onboard).to receive(:new).with(profile.employee).and_return(onboard_service)
          process.call
        end

        it 'emails TechTable' do
          expect(TechTableWorker).to receive(:perform_async).with(:onboard_instructions, transaction).once
          process.call
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

      it 'does not change worker status' do
        process.call
        expect(employee.status).to eq('active')
      end

      it 'updates security profiles' do
        expect(SecAccessService).to receive(:new).with(transaction)
        expect(sec_service).to receive(:apply_ad_permissions)
        process.call
      end

      it 'emails techtable' do
        expect(TechTableWorker).to receive(:perform_async).with(:permissions, transaction.id).once
        process.call
      end
    end
  end
end
