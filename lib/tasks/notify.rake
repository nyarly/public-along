namespace :notify do
  desc 'send p&c upcoming contract end notifications'
  task :hr_contract_end => :environment do
    contractors = EmployeeQuery.new.hr_contractor_notices

    contractors.each do |contractor|
      PeopleAndCultureMailer.upcoming_contract_end(contractor).deliver_now
    end unless contractors.empty?
  end
end
