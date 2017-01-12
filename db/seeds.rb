# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

depts = [
  {:name =>  "Facilities", :code => "000010"},
  {:name =>  "People & Culture", :code => "000011"},
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
  {:name =>  "Design", :code => "000063"},
  {:name =>  "Business Development", :code => "000070"}
]

locs = [
  {:name => "Leeds",:kind => "Remote Location",:country => "US",:status => "Active",:code => "LD"},
  {:name => "Berlin",:kind => "Remote Location",:country => "US",:status => "Active",:code => "BER"},
  {:name => "Birmingham",:kind => "Remote Location",:country => "US",:status => "Active",:code => "BM"},
  {:name => "London Office",:kind => "Office",:country => "GB",:status => "Active",:code => "LON"},
  {:name => "Los Angeles Office",:kind => "Office",:country => "US",:status => "Active",:code => "LOS"},
  {:name => "Massachusetts",:kind => "Remote Location",:country => "US",:status => "Active",:code => "MA"},
  {:name => "Manchester",:kind => "Remote Location",:country => "US",:status => "Active",:code => "MAN"},
  {:name => "Maryland",:kind => "Remote Location",:country => "US",:status => "Active",:code => "MD"},
  {:name => "Maine",:kind => "Remote Location",:country => "US",:status => "Active",:code => "ME"},
  {:name => "Melbourne Office",:kind => "Office",:country => "AU",:status => "Active",:code => "MEL"},
  {:name => "Michigan",:kind => "Remote Location",:country => "US",:status => "Active",:code => "MI"},
  {:name => "Minnesota",:kind => "Remote Location",:country => "US",:status => "Active",:code => "MN"},
  {:name => "Missouri",:kind => "Remote Location",:country => "US",:status => "Active",:code => "MO"},
  {:name => "Mumbai Office",:kind => "Office",:country => "IN",:status => "Active",:code => "MUM"},
  {:name => "Munich",:kind => "Remote Location",:country => "US",:status => "Active",:code => "MUN"},
  {:name => "Mexico City Office",:kind => "Office",:country => "MX",:status => "Active",:code => "MXC"},
  {:name => "North Carolina",:kind => "Remote Location",:country => "US",:status => "Active",:code => "NC"},
  {:name => "Northern California",:kind => "Remote Location",:country => "US",:status => "Active",:code => "NCA"},
  {:name => "Nebraska",:kind => "Remote Location",:country => "US",:status => "Active",:code => "NE"},
  {:name => "New Jersey",:kind => "Remote Location",:country => "US",:status => "Active",:code => "NJ"},
  {:name => "Nevada",:kind => "Remote Location",:country => "US",:status => "Active",:code => "NV"},
  {:name => "New York",:kind => "Remote Location",:country => "US",:status => "Active",:code => "NY"},
  {:name => "New York City Office",:kind => "Office",:country => "US",:status => "Active",:code => "NYC"},
  {:name => "Ohio",:kind => "Remote Location",:country => "US",:status => "Active",:code => "OH"},
  {:name => "Ontario",:kind => "Remote Location",:country => "CA",:status => "Active",:code => "ON"},
  {:name => "Oregon",:kind => "Remote Location",:country => "US",:status => "Active",:code => "OR"},
  {:name => "Pennsylvania",:kind => "Remote Location",:country => "US",:status => "Active",:code => "PA"},
  {:name => "Powai",:kind => "Remote Location",:country => "US",:status => "Active",:code => "POW"},
  {:name => "Quebec",:kind => "Remote Location",:country => "CA",:status => "Active",:code => "QC"},
  {:name => "South Carolina",:kind => "Remote Location",:country => "US",:status => "Active",:code => "SC"},
  {:name => "Southern California",:kind => "Remote Location",:country => "US",:status => "Active",:code => "SCA"},
  {:name => "San Francisco Headquarters",:kind => "Office",:country => "US",:status => "Active",:code => "SF"},
  {:name => "Sydney",:kind => "Remote Location",:country => "US",:status => "Active",:code => "SY"},
  {:name => "Tennessee",:kind => "Remote Location",:country => "US",:status => "Active",:code => "TN"},
  {:name => "Texas",:kind => "Remote Location",:country => "US",:status => "Active",:code => "TX"},
  {:name => "Tokyo Office",:kind => "Office",:country => "JP",:status => "Active",:code => "TYO"},
  {:name => "Utah",:kind => "Remote Location",:country => "US",:status => "Active",:code => "UT"},
  {:name => "Vermont",:kind => "Remote Location",:country => "US",:status => "Active",:code => "VT"},
  {:name => "Washington",:kind => "Remote Location",:country => "US",:status => "Active",:code => "WA"},
  {:name => "Wisconsin",:kind => "Remote Location",:country => "US",:status => "Active",:code => "WI"},
  {:name => "Alberta",:kind => "Remote Location",:country => "CA",:status => "Active",:code => "AB"},
  {:name => "Arizona",:kind => "Remote Location",:country => "US",:status => "Active",:code => "AZ"},
  {:name => "British Columbia",:kind => "Remote Location",:country => "CA",:status => "Active",:code => "BC"},
  {:name => "Bristol",:kind => "Remote Location",:country => "US",:status => "Active",:code => "BZ"},
  {:name => "Concord Distribution Center",:kind => "Remote Location",:country => "US",:status => "Active",:code => "CDC"},
  {:name => "Chicago Office",:kind => "Office",:country => "US",:status => "Active",:code => "CHI"},
  {:name => "Colorado",:kind => "Remote Location",:country => "US",:status => "Active",:code => "CO"},
  {:name => "Contractor",:kind => "Remote Location",:country => "US",:status => "Active",:code => "CONTR"},
  {:name => "Corby",:kind => "Remote Location",:country => "US",:status => "Active",:code => "COR"},
  {:name => "Cancun",:kind => "Remote Location",:country => "US",:status => "Active",:code => "CUN"},
  {:name => "Washington DC",:kind => "Remote Location",:country => "US",:status => "Active",:code => "DC"},
  {:name => "Denver Contact Center",:kind => "Remote Location",:country => "US",:status => "Active",:code => "DCC"},
  {:name => "Denver Office",:kind => "Office",:country => "US",:status => "Active",:code => "DEN"},
  {:name => "Denver CSR",:kind => "Remote Location",:country => "US",:status => "Active",:code => "DENCS"},
  {:name => "Dundee",:kind => "Remote Location",:country => "US",:status => "Active",:code => "DND"},
  {:name => "Edinburgh",:kind => "Remote Location",:country => "US",:status => "Active",:code => "EB"},
  {:name => "Florida",:kind => "Remote Location",:country => "US",:status => "Active",:code => "FL"},
  {:name => "Frankfurt Office",:kind => "Office",:country => "DE",:status => "Active",:code => "FRA"},
  {:name => "Georgia",:kind => "Remote Location",:country => "US",:status => "Active",:code => "GA"},
  {:name => "Glasgow",:kind => "Remote Location",:country => "US",:status => "Active",:code => "GLA"},
  {:name => "Hamburg",:kind => "Remote Location",:country => "US",:status => "Active",:code => "HAM"},
  {:name => "Hawaii",:kind => "Remote Location",:country => "US",:status => "Active",:code => "HI"},
  {:name => "Idaho",:kind => "Remote Location",:country => "US",:status => "Active",:code => "ID"},
  {:name => "Illinois",:kind => "Remote Location",:country => "US",:status => "Active",:code => "IL"},
  {:name => "Ireland",:kind => "Remote Location",:country => "IE",:status => "Active",:code => "IRL"},
  {:name => "Kentucky",:kind => "Remote Location",:country => "US",:status => "Active",:code => "KY"},
  {:name => "Louisiana",:kind => "Remote Location",:country => "US",:status => "Active",:code => "LA"},
]

mach_bundles = [
  {:name => 'PC Bundle', :description => 'T460, 27" Asus Monitor' },
  {:name => '13" Mac Bundle', :description => '13" MacBook Air, 27" Asus Monitor' },
  {:name => 'PC Bundle - Remote', :description => 'T460' },
  {:name => '13" Mac Bundle - Remote', :description => '13" MacBook Air' },
  {:name => 'PC Bundle - Engineer', :description => 'T460 (engineering), 27" Asus Monitor, Accessories' },
  {:name => '15" Mac Bundle', :description => '15" MacBook Pro, 27" Asus Monitor' },
  {:name => 'Customer Support', :description => 'T460, 2x 24" Monitors' },
  {:name => 'Special Equipment Bundle', :description => 'Please describe in notes to Tech Table below' },
  {:name => 'No Equipment Needed', :description => 'Tech Table will not provision any equipment' },
  {:name => 'Contingent Worker Mac', :description => 'Mac laptop, model depending on availability' },
  {:name => 'Contingent Worker PC', :description => 'PC laptop, model depending on availability' }
]

ActiveRecord::Base.transaction do
  depts.each { |attrs|
    dept = Department.find_or_create_by(name: attrs[:name])
    dept.update_attributes(attrs)
  }
  locs.each { |attrs|
    loc = Location.find_or_create_by(name: attrs[:name])
    loc.update_attributes(attrs)
  }
  mach_bundles.each { |attrs|
    mb = MachineBundle.find_or_create_by(name: attrs[:name])
    mb.update_attributes(attrs)
  }
end

dept_mach_bundles = [
  {:department_id => Department.find_by(:name => "BizOpti/Internal Systems Engineering").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Engineer").id},
  {:department_id => Department.find_by(:name => "BizOpti/Internal Systems Engineering").id, :machine_bundle_id => MachineBundle.find_by(:name => '15" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Brand/General Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Brand/General Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Business Development").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Business Development").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Consumer Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Consumer Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Consumer Product Management").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Engineer").id},
  {:department_id => Department.find_by(:name => "Consumer Product Management").id, :machine_bundle_id => MachineBundle.find_by(:name => '15" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Customer Support").id, :machine_bundle_id => MachineBundle.find_by(:name => 'Customer Support').id},
  {:department_id => Department.find_by(:name => "Data Analytics & Experimentation").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Engineer").id},
  {:department_id => Department.find_by(:name => "Data Analytics & Experimentation").id, :machine_bundle_id => MachineBundle.find_by(:name => '15" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Data Science").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Engineer").id},
  {:department_id => Department.find_by(:name => "Data Science").id, :machine_bundle_id => MachineBundle.find_by(:name => '15" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Design").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Engineer").id},
  {:department_id => Department.find_by(:name => "Design").id, :machine_bundle_id => MachineBundle.find_by(:name => '15" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Executive").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Executive").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Facilities").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Facilities").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Field Operations").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Field Operations").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Field Operations").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Remote").id},
  {:department_id => Department.find_by(:name => "Field Operations").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle - Remote').id},
  {:department_id => Department.find_by(:name => "Finance").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Finance Operations").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Infrastructure Engineering").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Engineer").id},
  {:department_id => Department.find_by(:name => "Infrastructure Engineering").id, :machine_bundle_id => MachineBundle.find_by(:name => '15" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Inside Sales").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Legal").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "People & Culture").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "People & Culture").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Product Engineering - Front End Diner").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Engineer").id},
  {:department_id => Department.find_by(:name => "Product Engineering - Front End Diner").id, :machine_bundle_id => MachineBundle.find_by(:name => '15" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Product Engineering - Front End Restaurant").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Engineer").id},
  {:department_id => Department.find_by(:name => "Product Engineering - Front End Restaurant").id, :machine_bundle_id => MachineBundle.find_by(:name => '15" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Product Engineering - Back End").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Engineer").id},
  {:department_id => Department.find_by(:name => "Product Engineering - Back End").id, :machine_bundle_id => MachineBundle.find_by(:name => '15" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Product Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Product Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Public Relations").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Public Relations").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Restaurant Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Restaurant Marketing").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Restaurant Product Management").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Restaurant Product Management").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Restaurant Relations Management").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Restaurant Relations Management").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Risk Management").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Risk Management").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Sales").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Sales").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Sales").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Remote").id},
  {:department_id => Department.find_by(:name => "Sales").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle - Remote').id},
  {:department_id => Department.find_by(:name => "Sales Operations").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Sales Operations").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Sales Operations").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Remote").id},
  {:department_id => Department.find_by(:name => "Sales Operations").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle - Remote').id},
  {:department_id => Department.find_by(:name => "Talent Acquisition").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "Tech Table").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Engineer").id},
  {:department_id => Department.find_by(:name => "Tech Table").id, :machine_bundle_id => MachineBundle.find_by(:name => '15" Mac Bundle').id},
  {:department_id => Department.find_by(:name => "Technology/CTO Admin").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Engineer").id},
  {:department_id => Department.find_by(:name => "Technology/CTO Admin").id, :machine_bundle_id => MachineBundle.find_by(:name => '15" Mac Bundle').id},
]

ActiveRecord::Base.transaction do
  dept_mach_bundles.each { |attrs| DeptMachBundle.find_or_create_by(attrs) }
  Department.find_each { |d|
    ["No Equipment Needed", "Special Equipment Bundle", "Contingent Worker Mac", "Contingent Worker PC"].each do |name|
      mb = MachineBundle.find_by(:name => name)
      d.machine_bundles << mb unless d.machine_bundles.include?(mb)
    end
  }
end
