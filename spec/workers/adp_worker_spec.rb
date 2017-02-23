require 'rails_helper'

RSpec.describe AdpWorker, type: :worker do
  let(:service) { double(AdpService::Workers) }
  let(:worker) { AdpWorker.new }

  it "should perform right away" do
    AdpWorker.perform_async("a url")

    expect(AdpWorker.jobs.size).to eq(1)
  end

  it "should instantiate AdpService::Workers class and call #sync_workers with url" do
    expect(AdpService::Workers).to receive(:new).and_return(service)
    expect(service).to receive(:sync_workers).with("a url")
    allow(Sidekiq::Logging.logger).to receive(:info).with("THIS IS THE URL: a url")
    allow(Sidekiq::Logging.logger).to receive(:info).with("RESULTS: ")

    worker.perform("a url")
  end

  it "should log info" do
    allow(AdpService::Workers).to receive(:new).and_return(service)
    allow(service).to receive(:sync_workers).with("a url").and_return({workers: "stuff"})

    expect(Sidekiq::Logging.logger).to receive(:info).with("THIS IS THE URL: a url")
    expect(Sidekiq::Logging.logger).to receive(:info).with("RESULTS: {:workers=>\"stuff\"}")

    worker.perform("a url")
  end

end
