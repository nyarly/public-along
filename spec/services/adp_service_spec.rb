require 'rails_helper'

describe AdpService, type: :service do
  let(:url)         { "https://accounts.adp.com/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:uri)         { double(URI) }
  let(:host)        { "accounts.adp.com" }
  let(:port)        { 443 }
  let(:request_uri) { "/auth/oauth/v2/token?grant_type=client_credentials" }
  let(:http)        { double(Net::HTTP) }
  let(:response)    { double(Net::HTTPResponse) }

  before :each do
    allow(uri).to receive(:host).and_return(host)
    allow(uri).to receive(:port).and_return(port)
    allow(uri).to receive(:request_uri).and_return(request_uri)
    allow(http).to receive(:cert=)
    allow(http).to receive(:key=)
    allow(OpenSSL::X509::Certificate).to receive(:new)
    allow(OpenSSL::PKey::RSA).to receive(:new)

    expect(URI).to receive(:parse).with(url).and_return(uri)
    expect(Net::HTTP).to receive(:new).with(host, port).and_return(http).at_least(:once)
    expect(http).to receive(:use_ssl=).with(true).at_least(:once)
    expect(http).to receive(:verify_mode=).with(OpenSSL::SSL::VERIFY_PEER).at_least(:once)
    expect(http).to receive(:post).with(
      request_uri,
      '',
      { "Accept"=>"application/json",
        "Authorization"=>"Basic #{SECRETS.adp_creds}",
      }).and_return(response)
    expect(response).to receive(:body).and_return('{"access_token": "7890f85c-43ef-4ebc-acb7-f98f2c0581d0"}')
  end

  describe "get_bearer_token" do
    it "should get a bearer token from ADP" do
      expect(AdpService.new.token).to eq("7890f85c-43ef-4ebc-acb7-f98f2c0581d0")
    end
  end

  describe "populate job titles table" do
    let!(:existing) { FactoryGirl.create(:job_title, code: "ACCNASST", name: "Accounting Assistant", status: "Active")}

    before :each do
      expect(URI).to receive(:parse).with("https://api.adp.com/codelists/hr/v3/worker-management/job-titles/WFN/1").and_return(uri)
      expect(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should find or create job titles" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"AASFE - Administrative Assistant","codeValue":"AASFE","longName":"Administrative Assistant"},{"valueDescription":"ACCNASST - Accounting Assistant","codeValue":"ACCNASST","shortName":"Accounting Assistant"},{"valueDescription":"ACCPAYSU - Accounts Payable Supervisor","codeValue":"ACCPAYSU","longName":"Accounts Payable Supervisor"}]}]}')

      adp = AdpService.new
      adp.token = "a-token-value"

      expect{
        adp.populate_job_titles
      }.to change{JobTitle.count}.from(1).to(3)
    end

    it "should update changes in existing job titles" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"AASFE - Administrative Assistant","codeValue":"AASFE","longName":"Administrative Assistant"},{"valueDescription":"ACCNASST - Accounting Assistant","codeValue":"ACCNASST","shortName":"New Accounting Assistant"},{"valueDescription":"ACCPAYSU - Accounts Payable Supervisor","codeValue":"ACCPAYSU","longName":"Accounts Payable Supervisor"}]}]}')

      adp = AdpService.new
      adp.token = "a-token-value"

      expect{
        adp.populate_job_titles
      }.to change{JobTitle.find_by(code: "ACCNASST").name}.from("Accounting Assistant").to("New Accounting Assistant")
    end

    it "should assign status dependent on presence in response body" do
      inactive = FactoryGirl.create(:job_title, code: "ACCPAYSU", name: "Accounts Payable Supervisor", status: "Active")

      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"AASFE - Administrative Assistant","codeValue":"AASFE","longName":"Administrative Assistant"},{"valueDescription":"ACCNASST - Accounting Assistant","codeValue":"ACCNASST","shortName":"New Accounting Assistant"}]}]}')

      adp = AdpService.new
      adp.token = "a-token-value"

      expect{
        adp.populate_job_titles
      }.to change{JobTitle.find_by(code: "ACCPAYSU").status}.from("Active").to("Inactive")
      expect(JobTitle.find_by(code: "AASFE").status).to eq("Active")
      expect(JobTitle.find_by(code: "ACCNASST").status).to eq("Active")
    end
  end

  xdescribe "populate locations table" do
    let!(:existing) { FactoryGirl.create(:location, code: "ACCNASST", name: "Accounting Assistant", status: "Active")}

    before :each do
      expect(URI).to receive(:parse).with("https://api.adp.com/codelists/hr/v3/worker-management/job-titles/WFN/1").and_return(uri)
      expect(http).to receive(:get).with(
        request_uri,
        { "Accept"=>"application/json",
          "Authorization"=>"Bearer a-token-value",
        }).and_return(response)
    end

    it "should find or create job titles" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"AASFE - Administrative Assistant","codeValue":"AASFE","longName":"Administrative Assistant"},{"valueDescription":"ACCNASST - Accounting Assistant","codeValue":"ACCNASST","shortName":"Accounting Assistant"},{"valueDescription":"ACCPAYSU - Accounts Payable Supervisor","codeValue":"ACCPAYSU","longName":"Accounts Payable Supervisor"}]}]}')

      adp = AdpService.new
      adp.token = "a-token-value"

      expect{
        adp.populate_job_titles
      }.to change{JobTitle.count}.from(1).to(3)
    end

    it "should update changes in existing job titles" do
      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"AASFE - Administrative Assistant","codeValue":"AASFE","longName":"Administrative Assistant"},{"valueDescription":"ACCNASST - Accounting Assistant","codeValue":"ACCNASST","shortName":"New Accounting Assistant"},{"valueDescription":"ACCPAYSU - Accounts Payable Supervisor","codeValue":"ACCPAYSU","longName":"Accounts Payable Supervisor"}]}]}')

      adp = AdpService.new
      adp.token = "a-token-value"

      expect{
        adp.populate_job_titles
      }.to change{JobTitle.find_by(code: "ACCNASST").name}.from("Accounting Assistant").to("New Accounting Assistant")
    end

    it "should assign status dependent on presence in response body" do
      inactive = FactoryGirl.create(:job_title, code: "ACCPAYSU", name: "Accounts Payable Supervisor", status: "Active")

      expect(response).to receive(:body).and_return('{"codeLists":[{"codeListTitle":"job-titles","listItems":[{"valueDescription":"AASFE - Administrative Assistant","codeValue":"AASFE","longName":"Administrative Assistant"},{"valueDescription":"ACCNASST - Accounting Assistant","codeValue":"ACCNASST","shortName":"New Accounting Assistant"}]}]}')

      adp = AdpService.new
      adp.token = "a-token-value"

      expect{
        adp.populate_job_titles
      }.to change{JobTitle.find_by(code: "ACCPAYSU").status}.from("Active").to("Inactive")
      expect(JobTitle.find_by(code: "AASFE").status).to eq("Active")
      expect(JobTitle.find_by(code: "ACCNASST").status).to eq("Active")
    end
  end
end
