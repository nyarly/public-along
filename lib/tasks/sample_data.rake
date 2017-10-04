namespace :db do
  namespace :sample_data do
    desc "load sample data"
    task :load => :environment do
      2.times do
        create_basic_new_hire(DateTime.now)
      end
    end

    desc "load lebowski"
    task :lebowski => :environment do
      employee = Employee.create!(
        first_name: 'Jeffrey',
        last_name: 'Lebowski',
        sam_account_name: 'jlebowski',
        email: 'jlebowski@opentable.com',
        hire_date: 10.years.ago
      )
      Profile.create!(
        employee: employee,
        start_date: Date.today,
        profile_status: "active",
        adp_employee_id: 'jlebowski123',
        business_title: 'The Dude Sr.',
        department_id: Department.find_by(name: "People & Culture-HR & Total Rewards").id,
        location_id: Location.find_by(name: "San Francisco Headquarters").id,
        job_title: JobTitle.find_or_create_by!(id: 1, name: "Test", code: "TEST", status: "Active"),
        worker_type: WorkerType.find_or_create_by!(id: 1, name: "Test", code: "TEST1", status: "Active")
      )
    end
  end
end

def create_basic_new_hire(hire_date)
  new_hire = Employee.create!(
    email: nil, # Regular new hires don't have an email
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    hire_date: hire_date,
    contract_end_date: nil,
    termination_date: nil,
    personal_mobile_phone: Faker::PhoneNumber.phone_number,
    office_phone: Faker::PhoneNumber.phone_number,
    home_address_1: nil,
    home_address_2: nil,
    home_city: nil,
    home_state: nil,
    home_zip: nil,
    image_code: IMAGE
  )
  Profile.create!(
    employee: new_hire,
    start_date: Date.today,
    profile_status: "active",
    end_date: nil,
    adp_employee_id: Faker::Number.number(6),
    business_title: Faker::Name.title,
    manager_id: nil,
    department_id: Department.all.map(&:id).sample,
    location_id: Location.all.map(&:id).sample,
    job_title: JobTitle.find_or_create_by!(id: 1, name: "Test", code: "TEST", status: "Active"),
    worker_type: WorkerType.find_or_create_by!(id: 1, name: "Test", code: "TEST1", status: "Active")
  )
end
