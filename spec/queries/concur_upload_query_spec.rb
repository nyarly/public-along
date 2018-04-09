require 'rails_helper'

describe ConcurUploadQuery, type: :query do
  describe '#daily_sync_group' do
    before do
      Timecop.freeze(Time.new(2018, 2, 14, 23, 30, 0, '+00:00'))
    end

    after do
      Timecop.return
    end

    context 'when employee started today' do
      subject(:upload_group) { ConcurUploadQuery.new.daily_sync_group }

      let(:new_employee) { FactoryGirl.create(:employee, status: 'active', hire_date: Date.new(2018, 2, 14)) }

      before do
        FactoryGirl.create(:profile,
          employee: new_employee,
          profile_status: 'active',
          start_date: Date.new(2018, 2, 14))
      end

      it 'includes worker' do
        expect(upload_group).to eq([new_employee])
      end
    end

    context 'when employee starts tomorrow' do
      subject(:upload_group) { ConcurUploadQuery.new.daily_sync_group }

      let(:new_employee) { FactoryGirl.create(:employee, status: 'pending') }

      before do
        FactoryGirl.create(:profile,
          employee: new_employee,
          profile_status: 'pending',
          start_date: Date.new(2018, 2, 15))
      end

      it 'they are not included' do
        expect(upload_group).not_to include(new_employee)
      end
    end

    context 'when worker has a change' do
      subject(:upload_group) { ConcurUploadQuery.new.daily_sync_group }

      let(:changed_employee) { FactoryGirl.create(:employee, status: 'active') }

      before do
        FactoryGirl.create(:profile,
          employee: changed_employee,
          profile_status: 'active')
        FactoryGirl.create(:emp_delta,
          employee: changed_employee,
          created_at: Time.new(2018, 2, 14, 8, 0, 0, '+00:00'),
          before: { 'business_title' => 'biz title' },
          after: { 'business_title' => 'business title' })
      end

      it 'includes worker' do
        expect(upload_group).to eq([changed_employee])
      end
    end

    context 'when direct reports change' do
      subject(:upload_group) { ConcurUploadQuery.new.daily_sync_group }

      let(:old_manager) { FactoryGirl.create(:active_employee) }
      let(:manager)     { FactoryGirl.create(:active_employee) }
      let(:employee)    { FactoryGirl.create(:active_employee, manager: manager) }
      let(:employee_2)  { FactoryGirl.create(:active_employee, manager: manager) }

      before do
        FactoryGirl.create(:emp_delta,
          employee: employee,
          before: { "manager_id" => "#{old_manager.id}" },
          after: { "manager_id" => "#{manager.id}" })
        FactoryGirl.create(:emp_delta,
          employee: employee_2,
          before: { "manager_id" => "#{old_manager.id}" },
          after: { "manager_id" => "#{manager.id}" })
      end

      it 'has the right number of workers to upload' do
        expect(upload_group.count).to eq(3)
      end

      it 'includes the manager' do
        expect(upload_group).to eq([manager, employee_2, employee])
      end
    end

    context 'when worker has a change and starts' do
      subject(:upload_group) { ConcurUploadQuery.new.daily_sync_group }

      let(:new_and_changed_employee) { FactoryGirl.create(:employee, status: 'active') }

      before do
        FactoryGirl.create(:profile,
          employee: new_and_changed_employee,
          profile_status: 'active',
          start_date: Date.new(2018, 2, 14))
        FactoryGirl.create(:emp_delta,
          employee: new_and_changed_employee,
          created_at: Time.new(2018, 2, 14, 8, 0, 0, '+00:00'),
          before: { 'business_title' => 'biz' },
          after: { 'business_title' => 'niz' })
      end

      it 'is only included once' do
        expect(upload_group).to eq([new_and_changed_employee])
      end
    end

    context 'when worker was terminated yesterday' do
      subject(:upload_group) { ConcurUploadQuery.new.daily_sync_group }

      let!(:terminated_employee) do
        FactoryGirl.create(:terminated_employee,
          termination_date: Date.new(2018, 2, 13))
      end

      it 'includes worker' do
        expect(upload_group).to eq([terminated_employee])
      end
    end

    context 'when worker terminated today' do
      subject(:upload_group) { ConcurUploadQuery.new.daily_sync_group }

      let(:term_today) do
        FactoryGirl.create(:active_employee,
          termination_date: Date.new(2018, 2, 14))
      end

      it 'they are not included' do
        expect(upload_group).not_to include(term_today)
      end
    end

    context 'when worker offboarded yesterday' do
      subject(:upload_group) { ConcurUploadQuery.new.daily_sync_group }

      let(:worker_type) { FactoryGirl.create(:worker_type, kind: 'Regular') }

      let(:offboarded) do
        FactoryGirl.create(:terminated_employee,
          termination_date: Date.new(2018, 2, 11),
          offboarded_at: Time.new(2018, 2, 13, 12, 0, 0, '+00:00'))
      end

      before do
        FactoryGirl.create(:profile,
          employee: offboarded,
          profile_status: 'terminated',
          worker_type: worker_type)
      end

      it 'includes worker' do
        expect(upload_group).to eq([offboarded])
      end
    end

    context 'when worker offboarded today' do
      subject(:upload_group) { ConcurUploadQuery.new.daily_sync_group }

      let(:worker_type) { FactoryGirl.create(:worker_type, kind: 'Regular') }

      let(:offboarded) do
        FactoryGirl.create(:terminated_employee,
          termination_date: Date.new(2018, 2, 11),
          offboarded_at: Time.new(2018, 2, 14, 12, 0, 0, '+00:00'))
      end

      before do
        FactoryGirl.create(:profile,
          employee: offboarded,
          profile_status: 'terminated',
          worker_type: worker_type)
      end

      it 'includes worker' do
        expect(upload_group).to eq([offboarded])
      end
    end

    context 'when worker is not regular worker' do
      subject(:upload_group) { ConcurUploadQuery.new.daily_sync_group }

      let(:temp) { FactoryGirl.create(:temp_worker, status: 'active') }
      let(:contractor) { FactoryGirl.create(:contract_worker, status: 'active') }

      before do
        FactoryGirl.create(:temp,
          employee: temp,
          profile_status: 'active',
          start_date: Date.new(2018, 2, 14))
        FactoryGirl.create(:emp_delta,
          employee: contractor,
          created_at: Time.new(2018, 2, 14, 8, 0, 0, '+00:00'),
          before: { 'business_title' => 'biz' },
          after: { 'business_title' => 'niz' })
      end

      it 'does not include contractors' do
        expect(upload_group).not_to include(contractor)
      end

      it 'does not include temps' do
        expect(upload_group).not_to include(temp)
      end
    end
  end
end
