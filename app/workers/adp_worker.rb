class AdpWorker
  include Sidekiq::Worker

  def perform(url)
    adp = AdpService::Workers.new
    result = adp.sync_workers(url)
    logger.info "THIS IS THE URL: #{url}"
    logger.info "RESULTS: #{result}"
  end
end
