namespace :db do
  namespace :betterworks do

  desc "generate csv"
  task :generate_csv => :environment do
    bs = BetterworksService.new
    bs.generate_employee_csv
  end

  desc "drop to betterworks via sftp"
  task :sftp_drop => :environment do
    bs = BetterworksService.new
    bs.sftp_drop
  end
end
