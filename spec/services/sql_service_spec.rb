require 'rails_helper'
extend RSpec::Matchers

describe SqlService, type: :service do
  let(:tiny_tds) { double(TinyTds::Client) }
  let(:sql_service) { SqlService.new }
  let(:employee) { FactoryGirl.create(:employee, termination_date: Date.today, sam_account_name: 'm_bmarley', email: 'bmarley@ottest.com') }
  let(:pool) { double(ConnectionPool) }

  before :each do
    allow(TinyTds::Client).to receive(:new).and_return(tiny_tds)
    allow(tiny_tds).to receive(:host)
    allow(tiny_tds).to receive(:username)
    allow(tiny_tds).to receive(:password)
    allow(tiny_tds).to receive(:active?).and_return(true)
    allow(tiny_tds).to receive(:close).and_return(true)

    allow(ConnectionPool).to receive(:new).and_return(pool)
    allow(sql_service).to receive(:send_log).and_return(0)
  end

  context "offboards all services successfully" do

    it "should deactivate all three sql services and close the connections" do
      expect(sql_service).to receive(:deactivate_charm).with(employee).once
      expect(sql_service).to receive(:deactivate_otanywhere).with(employee).once
      expect(sql_service).to receive(:deactivate_roms).with(employee).once
      expect(sql_service).to receive(:close_pool).with(pool).once

      sql_service.deactivate_all(employee)
    end

    it "should return an array of results" do
      allow(tiny_tds).to receive(:execute).and_return(tiny_tds)
      allow(tiny_tds).to receive(:do)
      allow(tiny_tds).to receive(:return_code).and_return(0)
      expect(sql_service).to receive(:close_pool).with(pool).once

      sql_service.deactivate_all(employee)

      expect(sql_service.results.length).to eq(7)
      expect(sql_service.results).to eq([0, 0, 0, 0, 0, 0, 0])
    end

    it "should deactivate and log charm with correct information on all three databases" do
      charm_str = "EXEC dbo.User_ActivationByDomainLogin @DomainLogin = 'opentable.com\\m_bmarley', @Activate = 0"
      na_log_str = "EXEC dbo.Log_LogServiceAction @UserAccount = 'opentable.com\\m_bmarley', @UserActivated = 0, @ProcExecuted = 'dbo.User_ActivationByDomainLogin', @Server = 'Admin', @Status = 0"
      eu_log_str = "EXEC dbo.Log_LogServiceAction @UserAccount = 'opentable.com\\m_bmarley', @UserActivated = 0, @ProcExecuted = 'dbo.User_ActivationByDomainLogin', @Server = 'Admin_EU', @Status = 0"
      asia_log_str = "EXEC dbo.Log_LogServiceAction @UserAccount = 'opentable.com\\m_bmarley', @UserActivated = 0, @ProcExecuted = 'dbo.User_ActivationByDomainLogin', @Server = 'Admin_Asia', @Status = 0"

      expect(sql_service).to receive(:deactivate).with(tiny_tds, charm_str, na_log_str)
      expect(sql_service).to receive(:deactivate).with(tiny_tds, charm_str, eu_log_str)
      expect(sql_service).to receive(:deactivate).with(tiny_tds, charm_str, asia_log_str)

      sql_service.deactivate_charm(employee)
    end

    it "should deactivate and log charm with correct information on all three databases" do
      charm_str = "EXEC dbo.User_Activation @Email = 'bmarley@ottest.com', @Activate = 0"
      na_log_str = "EXEC dbo.Log_LogServiceAction @UserAccount = 'bmarley@ottest.com', @UserActivated = 0, @ProcExecuted = 'dbo.User_Activation', @Server = 'OTAnywhere', @Status = 0"
      eu_log_str = "EXEC dbo.Log_LogServiceAction @UserAccount = 'bmarley@ottest.com', @UserActivated = 0, @ProcExecuted = 'dbo.User_Activation', @Server = 'OTAnywhere_EU', @Status = 0"
      asia_log_str = "EXEC dbo.Log_LogServiceAction @UserAccount = 'bmarley@ottest.com', @UserActivated = 0, @ProcExecuted = 'dbo.User_Activation', @Server = 'OTAnywhere_Asia', @Status = 0"

      expect(sql_service).to receive(:deactivate).with(tiny_tds, charm_str, na_log_str)
      expect(sql_service).to receive(:deactivate).with(tiny_tds, charm_str, eu_log_str)
      expect(sql_service).to receive(:deactivate).with(tiny_tds, charm_str, asia_log_str)

      sql_service.deactivate_otanywhere(employee)
    end

    it "should deactivate and log roms with correct information" do
      roms_str = "EXEC dbo.ROMS_EmployeeActivation @EmployeeLoginID = 'opentable.com\\m_bmarley', @Activate = 0"
      log_str =  "EXEC dbo.Log_LogServiceAction @UserAccount = 'opentable.com\\m_bmarley', @UserActivated = 0, @ProcExecuted = 'dbo.ROMS_EmployeeActivation', @Server = 'GOD', @Status = 0"

      expect(sql_service).to receive(:deactivate).with(tiny_tds, roms_str, log_str)
      sql_service.deactivate_roms(employee)
    end

  end

  context "offboard services fail" do
    it "should return an array of results" do
      allow(tiny_tds).to receive(:execute).and_return(tiny_tds)
      allow(tiny_tds).to receive(:do)
      allow(tiny_tds).to receive(:return_code).and_return(+1)
      expect(sql_service).to receive(:close_pool).with(pool).once

      sql_service.deactivate_all(employee)

      expect(sql_service.results.length).to eq(7)
      expect(sql_service.results).to eq([+1, +1, +1, +1, +1, +1, +1])
    end

    it "should rescue errors from tiny_tds" do
      allow(tiny_tds).to receive(:execute).and_return(tiny_tds)
      allow(tiny_tds).to receive(:do).and_raise(StandardError.new)
      expect(sql_service).to receive(:close_pool).with(pool).once

      sql_service.deactivate_all(employee)

      expect(Rails.logger.error).to be(true)
      expect(sql_service.results).to eq([-1, -1, -1, -1, -1, -1, -1])
    end
  end
end
