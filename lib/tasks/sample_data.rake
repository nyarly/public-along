namespace :db do
  namespace :sample_data do
    desc "load sample data"
    task :load => :environment do
      2.times do
        create_basic_new_hire(DateTime.now)
      end
  end
end

def create_basic_new_hire(hire_date)
  Employee.create!(
        email: nil, # Regular new hires don't have an email
        first_name: Faker::Name.first_name,
        last_name: Faker::Name.last_name,
        workday_username: Faker::Number.number(10),
        employee_id: Faker::Number.number(10),
        country: ['US', 'GB', 'AU', 'JP'].sample,
        hire_date: hire_date,
        contract_end_date: nil,
        termination_date: nil,
        job_family_id: Faker::Number.number(10),
        job_family: Faker::Lorem.words(3).join(' '),
        job_profile_id: Faker::Number.number(10),
        job_profile: Faker::Name.title,
        business_title: Faker::Name.title,
        employee_type: 'Regular',
        contingent_worker_id: nil,
        contingent_worker_type: nil,
        location_type: 'HQ',
        location: 'OT_San_Francisco',
        manager_id: nil,
        cost_center: 'OT People and Culture',
        cost_center_id: nil,
        personal_mobile_phone: Faker::PhoneNumber.phone_number,
        office_phone: Faker::PhoneNumber.phone_number,
        home_address_1: nil,
        home_address_2: nil,
        home_city: nil,
        home_state: nil,
        home_zip: nil,
        image_code: IMAGE,
      )
    end
end
