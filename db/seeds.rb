# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

depts = [
  {:name =>  "Facilities", :code => "000010"},
  {:name =>  "People and Culture", :code => "000011"},
  {:name =>  "Legal", :code => "000012"},
  {:name =>  "Finance", :code => "000013"},
  {:name =>  "Risk Management", :code => "000014"},
  {:name =>  "Talent Acquisition", :code => "000017"},
  {:name =>  "Executive", :code => "000018"},
  {:name =>  "Finance Operations", :code => "000019"},
  {:name =>  "Sales", :code => "000020"},
  {:name =>  "Sales Operations", :code => "000021"},
  {:name =>  "Inside Sales", :code => "000025"},
  {:name =>  "Field Operations", :code => "000031"},
  {:name =>  "Customer Support", :code => "000032"},
  {:name =>  "Restaurant Relations Management", :code => "000033"},
  {:name =>  "Tech Table", :code => "000035"},
  {:name =>  "Infrastructure Engineering", :code => "000036"},
  {:name =>  "Technology/CTO Admin", :code => "000040"},
  {:name =>  "Product Engineering - Front End Diner", :code => "000041"},
  {:name =>  "Product Engineering - Front End Restaurant", :code => "000042"},
  {:name =>  "Product Engineering - Back End", :code => "000043"},
  {:name =>  "BizOpti/Internal Systems Engineering", :code => "000044"},
  {:name =>  "Data Analytics & Experimentation", :code => "000045"},
  {:name =>  "Data Science", :code => "000046"},
  {:name =>  "Brand/General Marketing", :code => "000050"},
  {:name =>  "Consumer Marketing", :code => "000051"},
  {:name =>  "Restaurant Marketing", :code => "000052"},
  {:name =>  "Public Relations", :code => "000053"},
  {:name =>  "Product Marketing", :code => "000054"},
  {:name =>  "Restaurant Product Management", :code => "000061"},
  {:name =>  "Consumer Product Management", :code => "000062"},
  {:name =>  "Business Development", :code => "000070"}
]

locs = [
  { :name => "San Francisco", :kind => "Office", :country => "US" },
  { :name => "Los Angeles", :kind => "Office", :country => "US" },
  { :name => "Denver", :kind => "Office", :country => "US" },
  { :name => "Chattanooga", :kind => "Office", :country => "US" },
  { :name => "Chicago", :kind => "Office", :country => "US" },
  { :name => "New York", :kind => "Office", :country => "US" },
  { :name => "Mexico City", :kind => "Office", :country => "MX" },
  { :name => "London", :kind => "Office", :country => "GB" },
  { :name => "Frankfurt", :kind => "Office", :country => "DE" },
  { :name => "Mumbai", :kind => "Office", :country => "IN" },
  { :name => "Tokyo", :kind => "Office", :country => "JP" },
  { :name => "Melbourne", :kind => "Office", :country => "AU" },
  { :name => "Arizona", :kind => "Remote Location", :country => "US" },
  { :name => "Colorado", :kind => "Remote Location", :country => "US" },
  { :name => "Illinois", :kind => "Remote Location", :country => "US" },
  { :name => "Tennessee", :kind => "Remote Location", :country => "US" },
  { :name => "Southern California", :kind => "Remote Location", :country => "US" },
  { :name => "Minnesota", :kind => "Remote Location", :country => "US" },
  { :name => "Maine", :kind => "Remote Location", :country => "US" },
  { :name => "Georgia", :kind => "Remote Location", :country => "US" },
  { :name => "Canada", :kind => "Remote Location", :country => "CA" },
  { :name => "Washington DC", :kind => "Remote Location", :country => "US" },
  { :name => "Pennsylvania", :kind => "Remote Location", :country => "US" },
  { :name => "Oregon", :kind => "Remote Location", :country => "US" },
  { :name => "Wisconsin", :kind => "Remote Location", :country => "US" },
  { :name => "Texas", :kind => "Remote Location", :country => "US" },
  { :name => "Ohio", :kind => "Remote Location", :country => "US" },
  { :name => "Massachusetts", :kind => "Remote Location", :country => "US" },
  { :name => "Washington", :kind => "Remote Location", :country => "US" },
  { :name => "Florida", :kind => "Remote Location", :country => "US" },
  { :name => "Nevada", :kind => "Remote Location", :country => "US" },
  { :name => "New Jersey", :kind => "Remote Location", :country => "US" },
  { :name => "Hawaii", :kind => "Remote Location", :country => "US" },
  { :name => "Vermont", :kind => "Remote Location", :country => "US" },
  { :name => "Missouri", :kind => "Remote Location", :country => "US" },
  { :name => "Louisiana", :kind => "Remote Location", :country => "US" },
  { :name => "Michigan", :kind => "Remote Location", :country => "US" },
  { :name => "Ireland", :kind => "Remote Location", :country => "IE" },
  { :name => "North Carolina", :kind => "Remote Location", :country => "US" },
  { :name => "Idaho", :kind => "Remote Location", :country => "US" },
  { :name => "Maryland", :kind => "Remote Location", :country => "US" },
  { :name => "Utah", :kind => "Remote Location", :country => "US" },
  { :name => "Kentucky", :kind => "Remote Location", :country => "US" }
]

mach_bundles = [
  {:name => 'Mac Bundle - Engineering', :description => 'MacBook Pro 15", 27" Asus Monitor, Accessories' },
  {:name => 'PC Bundle - Engineering', :description => 'T460 (engineering), 27" Asus Monitor, Accessories' },
  {:name => 'PC Bundle', :description => 'T460, 27" Asus Monitor, Accessories' },
  {:name => 'Mac Bundle', :description => '13" MacBook Air, Asus Monitor, Accessories' },
  {:name => 'PC Bundle - Remote', :description => 'T460, Accessories, Verizon Jetpack' },
  {:name => 'Mac Bundle - Remote', :description => '13" MacBook Air, Accessories, Verizon Jetpack' },
  {:name => 'Mac Bundle - Designer', :description => '15" MacBook Pro, Thunderbolt Display, Accessories' },
  {:name => 'No Equipment Needed', :description => '' },
]

ActiveRecord::Base.transaction do
  depts.each { |attrs| Department.create(attrs) }
  locs.each { |attrs| Location.create(attrs) }
  mach_bundles.each { |attrs| MachineBundle.create(attrs) }
end

dept_mach_bundles = [
  {:department_id => Department.find_by(:name => "Sales").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Sales").id, :machine_bundle_id => MachineBundle.find_by(:name => "Mac Bundle").id},
  {:department_id => Department.find_by(:name => "Sales").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Remote").id},
  {:department_id => Department.find_by(:name => "Sales").id, :machine_bundle_id => MachineBundle.find_by(:name => "Mac Bundle - Remote").id},
  {:department_id => Department.find_by(:name => "Restaurant Relations Management").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Restaurant Relations Management").id, :machine_bundle_id => MachineBundle.find_by(:name => "Mac Bundle").id},
  {:department_id => Department.find_by(:name => "Restaurant Relations Management").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Remote").id},
  {:department_id => Department.find_by(:name => "Restaurant Relations Management").id, :machine_bundle_id => MachineBundle.find_by(:name => "Mac Bundle - Remote").id},
  {:department_id => Department.find_by(:name => "Customer Support").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Finance Operations").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "People and Culture").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Brand/General Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Brand/General Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => "Mac Bundle").id},
  {:department_id => Department.find_by(:name => "Brand/General Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => "Mac Bundle - Designer").id},
  {:department_id => Department.find_by(:name => "Consumer Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Consumer Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => "Mac Bundle").id},
  {:department_id => Department.find_by(:name => "Restaurant Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Restaurant Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => "Mac Bundle").id},
  {:department_id => Department.find_by(:name => "Finance").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Legal").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
]

ActiveRecord::Base.transaction do
  dept_mach_bundles.each { |attrs| DeptMachBundle.create(attrs) }
end
