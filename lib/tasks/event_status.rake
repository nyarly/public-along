namespace :event_status do
  desc "downcase all adp event statuses for state machine"
  task :update => :environment do
    AdpEvent.all.each do |event|
      event.status = event.status.downcase
      event.save!
    end
  end
end
