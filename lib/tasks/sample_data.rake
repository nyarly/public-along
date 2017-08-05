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
      Employee.create(
        first_name: 'Jeffrey',
        last_name: 'Lebowski',
        sam_account_name: 'jlebowski',
        email: 'jlebowski@opentable.com',
        employee_id: 'jlebowski123',
        business_title: 'The Dude Sr.',
        department_id: Department.find_by(name: "People & Culture-HR & Total Rewards").id,
        location_id: Location.find_by(name: "San Francisco Headquarters").id,
        hire_date: 10.years.ago,
        job_title: JobTitle.find_or_create_by!(id: 1, name: "Test", code: "TEST", status: "Active"),
        worker_type: WorkerType.find_or_create_by!(id: 1, name: "Test", code: "TEST1", status: "Active")
      )
    end
  end
end

def create_basic_new_hire(hire_date)
  Employee.create!(
    email: nil, # Regular new hires don't have an email
    first_name: Faker::Name.first_name,
    last_name: Faker::Name.last_name,
    employee_id: Faker::Number.number(10),
    hire_date: hire_date,
    contract_end_date: nil,
    termination_date: nil,
    business_title: Faker::Name.title,
    manager_id: nil,
    department_id: Department.all.map(&:id).sample,
    location_id: Location.all.map(&:id).sample,
    personal_mobile_phone: Faker::PhoneNumber.phone_number,
    office_phone: Faker::PhoneNumber.phone_number,
    home_address_1: nil,
    home_address_2: nil,
    home_city: nil,
    home_state: nil,
    home_zip: nil,
    image_code: IMAGE,
    job_title: JobTitle.find_or_create_by!(id: 1, name: "Test", code: "TEST", status: "Active"),
    worker_type: WorkerType.find_or_create_by!(id: 1, name: "Test", code: "TEST1", status: "Active")
  )
end
