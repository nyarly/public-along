namespace :betterworks do

  desc "generate bet csv"
  task :generate_csv => :environment do
    bs = BetterworksService.new
    bs.generate_employee_csv
  end

  desc "drop to betterworks via sftp"
  task :sftp_drop => [:environment, :generate_csv] do
    bs = BetterworksService.new
    bs.sftp_drop
  end
end
