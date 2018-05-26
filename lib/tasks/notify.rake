namespace :notify do
  desc 'Send HR notice for temporary worker contract expiring in three weeks'
  task hr_temp_expiration: :environment do
    time_range = 3.weeks
    worker_type_kind = 'Temporary'

    temps = Employees::WithExpiringContract.call(time_range: time_range, worker_type_kind: worker_type_kind)

    temps.each do |temp|
      SendHrTempExpirationNotice.perform_async(temp.id)
    end
  end

  desc 'Send manager offboarding forms for contracts expiring in two weeks'
  task manager_contract_expiration: :environment do
    contractors = Employees::WithExpiringContract.call

    contractors.each do |contractor|
      SendManagerOffboardForm.perform_async(contractor.id)
    end
  end
end
