namespace :adp do
  desc "sync adp codelists"
  task :sync_codelists => :environment do
    c = AdpService::CodeLists.new
    c.sync_job_titles
    c.sync_locations
    c.sync_departments
    c.sync_worker_types
  end

  desc "poll adp events"
  task :sync_events => :environment do
    e = AdpService::Events.new
    e.get_events
  end

  desc "sync adp workers collection"
  task :sync_workers => :environment do
    w = AdpService::Workers.new
    w.create_sidekiq_workers
    w.check_new_hire_changes
    w.check_leave_return
  end

  desc "sync all adp info"
  task :sync_all => [:sync_codelists, :sync_events, :sync_workers]
end
