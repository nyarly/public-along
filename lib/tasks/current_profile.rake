namespace :current_profile do
  desc 'one time population of current profile employee field'
  task initial_population: :environment do
    ActiveRecord::Base.transaction do
      Employee.all.find_each do |employee|

        if employee.status == 'active'
          cp = employee.profiles.active.last.id
          employee.current_profile = Profile.find(cp)
        elsif employee.status == 'inactive'
          cp = employee.profiles.leave.last.id
          employee.current_profile = Profile.find(cp)
        elsif employee.status == 'terminated'
          cp = employee.profiles.terminated.last.id
          employee.current_profile = Profile.find(cp)
        elsif employee.status == 'pending'
          cp = employee.profiles.pending.last.id
          employee.current_profile = Profile.find(cp)
        else
          puts "Unable to update on #{employee.cn} with ID #{employee.id}"
        end

        if employee.current_profile.blank?
          cp = employee.profiles.last.id
          employee.current_profile = Profile.find(cp)
        end

        employee.current_profile.save!
        employee.save!
      end
    end
  end
end
