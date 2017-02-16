class AdpWorker
  include Sidekiq::Worker

  def perform(url)
    adp = AdpService::Workers.new
    workers = adp.sync_workers(url)
    logger.info "THIS IS THE URL: #{url}"
    logger.info "WORKERS_PROCESSED: #{workers.inspect}"
  end
end
