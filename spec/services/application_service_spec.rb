require 'rails_helper'

describe ApplicationService, type: :service do
  let(:sql_service) { instance_double(SqlService) }
  let(:google_apps) { instance_double(GoogleAppsService) }
  let(:mailer)      { double(TechTableMailer) }
  let(:results)     { { 'Google Apps' => 'completed', 'Admin' => 'success' } }
  let(:employee) do
    FactoryGirl.create(:terminated_employee,
      termination_date: Date.new(2017, 6, 1))
  end

  describe '#offboard' do
    let(:service) { ApplicationService.new(employee) }

    before do
      allow(SqlService).to receive(:new).and_return(sql_service)
      allow(sql_service).to receive(:deactivate_all).with(employee).and_return('Admin' => 'success')
      allow(google_apps).to receive(:process).with(employee).and_return('completed')
      allow(GoogleAppsService).to receive(:new).and_return(google_apps)
      allow(TechTableMailer).to receive(:offboard_status).with(employee, results).and_return(mailer)
      allow(mailer).to receive(:deliver_now)
      service.offboard_all_apps
    end

    it 'transfers google drive' do
      expect(google_apps).to have_received(:process).with(employee)
    end

    it 'deactivates worker in sql dbs' do
      expect(sql_service).to have_received(:deactivate_all).with(employee)
    end

    it 'returns a results hash' do
      expect(service.results).to eq(results)
    end

    it 'sends the results to techtable' do
      expect(TechTableMailer).to have_received(:offboard_status).with(employee, results)
    end
  end
end
