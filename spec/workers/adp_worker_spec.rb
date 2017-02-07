require 'rails_helper'

RSpec.describe AdpWorker, type: :worker do
  let(:service) { double(AdpService) }
  let(:worker) { AdpWorker.new }

  it "should perform right away" do
    AdpWorker.perform_async("a url")

    expect(AdpWorker.jobs.size).to eq(1)
  end

  it "should instantiate AdpService class and call #populate_workers with url" do
    expect(AdpService).to receive(:new).and_return(service)
    expect(service).to receive(:populate_workers).with("a url")
    allow(Sidekiq::Logging.logger).to receive(:info).with("THIS IS THE URL: a url")
    allow(Sidekiq::Logging.logger).to receive(:info).with("WORKERS_PROCESSED: nil")

    worker.perform("a url")
  end

  it "should log info" do
    allow(AdpService).to receive(:new).and_return(service)
    allow(service).to receive(:populate_workers).with("a url").and_return({workers: "stuff"})

    expect(Sidekiq::Logging.logger).to receive(:info).with("THIS IS THE URL: a url")
    expect(Sidekiq::Logging.logger).to receive(:info).with("WORKERS_PROCESSED: {:workers=>\"stuff\"}")

    worker.perform("a url")
  end

end
