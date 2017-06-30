# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

depts = [
  {:name =>  "Facilities", :code => "010000", :status => "Active"},
  {:name =>  "People & Culture-HR & Total Rewards", :code => "011000", :status => "Active"},
  {:name =>  "Legal", :code => "012000", :status => "Active"},
  {:name =>  "Finance", :code => "013000", :status => "Active"},
  {:name =>  "Risk Management", :code => "014000", :status => "Active"},
  {:name =>  "People & Culture-Talent Acquisition", :code => "017000", :status => "Active"},
  {:name =>  "Executive", :code => "018000", :status => "Active"},
  {:name =>  "Finance Operations", :code => "019000", :status => "Active"},
  {:name =>  "Sales", :code => "020000", :status => "Active"},
  {:name =>  "Sales Operations", :code => "021000", :status => "Active"},
  {:name =>  "Inside Sales", :code => "025000", :status => "Active"},
  {:name =>  "Field Operations", :code => "031000", :status => "Active"},
  {:name =>  "Customer Support", :code => "032000", :status => "Active"},
  {:name =>  "Restaurant Relations Management", :code => "033000", :status => "Active"},
  {:name =>  "Tech Table", :code => "035000", :status => "Active"},
  {:name =>  "Infrastructure Engineering", :code => "036000", :status => "Active"},
  {:name =>  "Technology/CTO Admin", :code => "040000", :status => "Active"},
  {:name =>  "Product Engineering - Front End Diner", :code => "041000", :status => "Active"},
  {:name =>  "Product Engineering - Front End Restaurant", :code => "042000", :status => "Active"},
  {:name =>  "Product Engineering - Back End", :code => "043000", :status => "Active"},
  {:name =>  "BizOpti/Internal System Engineering", :code => "044000", :status => "Active"},
  {:name =>  "Data Analytics & Experimentation", :code => "045000", :status => "Active"},
  {:name =>  "Data Science", :code => "046000", :status => "Active"},
  {:name =>  "Brand/General Marketing", :code => "050000", :status => "Active"},
  {:name =>  "Consumer Marketing", :code => "051000", :status => "Active"},
  {:name =>  "Restaurant Marketing", :code => "052000", :status => "Active"},
  {:name =>  "Public Relations", :code => "053000", :status => "Active"},
  {:name =>  "Product Marketing", :code => "054000", :status => "Active"},
  {:name =>  "Restaurant Product Management", :code => "061000", :status => "Active"},
  {:name =>  "Consumer Product Management", :code => "062000", :status => "Active"},
  {:name =>  "Design", :code => "063000", :status => "Active"},
  {:name =>  "Business Development", :code => "070000", :status => "Active"}
]

locs = [{:name=>"Leeds", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"LD", :timezone=>"(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"},
 {:name=>"Berlin", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"BER", :timezone=>"(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"},
 {:name=>"Birmingham", :kind=>"Remote Location", :country=>"GB", :status=>"Active", :code=>"BM", :timezone=>"(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"},
 {:name=>"London Office", :kind=>"Office", :country=>"GB", :status=>"Active", :code=>"LON", :timezone=>"(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"},
 {:name=>"Los Angeles Office", :kind=>"Office", :country=>"US", :status=>"Active", :code=>"LOS", :timezone=>"(GMT-08:00) Pacific Time (US & Canada), Tijuana"},
 {:name=>"Massachusetts", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"MA", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Manchester", :kind=>"Remote Location", :country=>"GB", :status=>"Active", :code=>"MAN", :timezone=>"(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"},
 {:name=>"Maryland", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"MD", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Maine", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"ME", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Melbourne Office", :kind=>"Office", :country=>"AU", :status=>"Active", :code=>"MEL", :timezone=>"(GMT+10:00) Canberra, Melbourne, Sydney"},
 {:name=>"Michigan", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"MI", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Minnesota", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"MN", :timezone=>"(GMT-06:00) Central Time (US & Canada)"},
 {:name=>"Missouri", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"MO", :timezone=>"(GMT-06:00) Central Time (US & Canada)"},
 {:name=>"Mumbai Office", :kind=>"Office", :country=>"IN", :status=>"Active", :code=>"MUM", :timezone=>"(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi"},
 {:name=>"Munich", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"MUN", :timezone=>"(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"},
 {:name=>"Mexico City Office", :kind=>"Office", :country=>"MX", :status=>"Active", :code=>"MXC", :timezone=>"(GMT-06:00) Central Time (US & Canada)"},
 {:name=>"North Carolina", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"NC", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Northern California", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"NCA", :timezone=>"(GMT-08:00) Pacific Time (US & Canada), Tijuana"},
 {:name=>"Nebraska", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"NE", :timezone=>"(GMT-06:00) Central Time (US & Canada)"},
 {:name=>"New Jersey", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"NJ", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Nevada", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"NV", :timezone=>"(GMT-08:00) Pacific Time (US & Canada), Tijuana"},
 {:name=>"New York", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"NY", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"New York City Office", :kind=>"Office", :country=>"US", :status=>"Active", :code=>"NYC", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Ohio", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"OH", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Ontario", :kind=>"Remote Location", :country=>"CA", :status=>"Active", :code=>"ON", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Oregon", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"OR", :timezone=>"(GMT-08:00) Pacific Time (US & Canada), Tijuana"},
 {:name=>"Pennsylvania", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"PA", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Powai", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"POW", :timezone=>"(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi"},
 {:name=>"Quebec", :kind=>"Remote Location", :country=>"CA", :status=>"Active", :code=>"QC", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"South Carolina", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"SC", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Southern California", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"SCA", :timezone=>"(GMT-08:00) Pacific Time (US & Canada), Tijuana"},
 {:name=>"San Francisco Headquarters", :kind=>"Office", :country=>"US", :status=>"Active", :code=>"SF", :timezone=>"(GMT-08:00) Pacific Time (US & Canada), Tijuana"},
 {:name=>"Sydney", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"SY", :timezone=>"(GMT+10:00) Canberra, Melbourne, Sydney"},
 {:name=>"Tennessee", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"TN", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Texas", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"TX", :timezone=>"(GMT-06:00) Central Time (US & Canada)"},
 {:name=>"Tokyo Office", :kind=>"Office", :country=>"JP", :status=>"Active", :code=>"TYO", :timezone=>"(GMT+09:00) Osaka, Sapporo, Tokyo"},
 {:name=>"Utah", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"UT", :timezone=>"(GMT-07:00) Mountain Time (US & Canada)"},
 {:name=>"Vermont", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"VT", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Washington", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"WA", :timezone=>"(GMT-08:00) Pacific Time (US & Canada), Tijuana"},
 {:name=>"Wisconsin", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"WI", :timezone=>"(GMT-06:00) Central Time (US & Canada)"},
 {:name=>"Alberta", :kind=>"Remote Location", :country=>"CA", :status=>"Active", :code=>"AB", :timezone=>"(GMT-07:00) Mountain Time (US & Canada)"},
 {:name=>"Arizona", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"AZ", :timezone=>"(GMT-07:00) Mountain Time (US & Canada)"},
 {:name=>"British", :kind=>"Remote Location", :country=>"CA", :status=>"Active", :code=>"BC", :timezone=>"Columbia  (GMT-08:00) Pacific Time (US & Canada), Tijuana"},
 {:name=>"Bristol", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"BZ", :timezone=>"(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"},
 {:name=>"Concord Distribution Center", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"CDC", :timezone=>"(GMT-08:00) Pacific Time (US & Canada), Tijuana"},
 {:name=>"Chicago Office", :kind=>"Office", :country=>"US", :status=>"Active", :code=>"CHI", :timezone=>"(GMT-06:00) Central Time (US & Canada)"},
 {:name=>"Colorado", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"CO", :timezone=>"(GMT-07:00) Mountain Time (US & Canada)"},
 {:name=>"CONTRACT", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"CONTR", :timezone=>"(GMT-08:00) Pacific Time (US & Canada), Tijuana"},
 {:name=>"Corby", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"COR", :timezone=>"(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"},
 {:name=>"Cancun", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"CUN", :timezone=>" (GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Washington", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"DC", :timezone=>"DC (GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Denver Contact Center", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"DCC", :timezone=>"(GMT-07:00) Mountain Time (US & Canada)"},
 {:name=>"Denver Office", :kind=>"Office", :country=>"US", :status=>"Active", :code=>"DEN", :timezone=>"(GMT-07:00) Mountain Time (US & Canada)"},
 {:name=>"Denver CSR", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"DENCS", :timezone=>"(GMT-07:00) Mountain Time (US & Canada) Local Office"},
 {:name=>"Dundee", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"DND", :timezone=>"(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"},
 {:name=>"Edinburgh", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"EB", :timezone=>"(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"},
 {:name=>"Florida", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"FL", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Frankfurt Office", :kind=>"Office", :country=>"DE", :status=>"Active", :code=>"FRA", :timezone=>"(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"},
 {:name=>"Georgia", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"GA", :timezone=>"(GMT-05:00) Eastern Time (US & Canada)"},
 {:name=>"Glasgow", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"GLA", :timezone=>"(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"},
 {:name=>"Hamburg", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"HAM", :timezone=>"(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna"},
 {:name=>"Hawaii", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"HI", :timezone=>"(GMT-10:00) Hawaii"},
 {:name=>"Idaho", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"ID", :timezone=>"(GMT-07:00) Mountain Time (US & Canada)"},
 {:name=>"Illinois", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"IL", :timezone=>"(GMT-06:00) Central Time (US & Canada)"},
 {:name=>"Ireland", :kind=>"Remote Location", :country=>"IE", :status=>"Active", :code=>"IRL", :timezone=>"(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London"},
 {:name=>"Kentucky", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"KY", :timezone=>"(GMT-06:00) Central Time (US & Canada)"},
 {:name=>"Louisiana", :kind=>"Remote Location", :country=>"US", :status=>"Active", :code=>"LA", :timezone=>"(GMT-06:00) Central Time (US & Canada)"},
 {:code=>"NSW", :kind=>"Remote Location", :status=>"Active", :country=>"AU", :name=>"New South Wales", :timezone=>"(GMT+10:00) Canberra, Melbourne, Sydney"},
 {:code=>"QLD", :kind=>"Remote Location", :status=>"Active", :country=>"AU", :name=>"Queensland", :timezone=>"(GMT+10:00) Canberra, Melbourne, Sydney"},
 {:code=>"VIC", :kind=>"Remote Location", :status=>"Active", :country=>"AU", :name=>"Victoria", :timezone=>"(GMT+10:00) Canberra, Melbourne, Sydney"}]


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

worker_types = [
  {:name => "Regular Full-Time", :code => "FTR", :kind => "Regular", :status => "Active" },
  {:name => "Regular Part-Time", :code => "PTR", :kind => "Regular", :status => "Active" },
  {:name => "Agency Contract Worker", :code => "CTR", :kind => "Temporary", :status => "Active" },
]

job_titles = [
  {:name => "Engineer", :code => "ENG", :status => "Active" },
  {:name => "Administrative Assistant", :code => "ADM", :status => "Active"}
]

employees = [
  {:first_name => "Eleanor", :last_name => "Roosevelt", :employee_id => "12345", :hire_date => Date.today, :location => Location.find_by(:status => "Active"), :department => Department.find_by(:status => "Active"), :worker_type => WorkerType.find_by(:status => "Active"), :job_title => JobTitle.find_by(:status => "Active")},
  {:first_name => "Snow", :last_name => "White", :employee_id => "12346", :hire_date => Date.today, :location => Location.find_by(:status => "Active"), :department => Department.find_by(:status => "Active"), :worker_type => WorkerType.find_by(:status => "Active"), :job_title => JobTitle.find_by(:status => "Active")}
]

ActiveRecord::Base.transaction do
  depts.each { |attrs|
    dept = Department.find_or_create_by(name: attrs[:name], code: attrs[:code], status: attrs[:status])
    dept.update_attributes(attrs)
  }
  locs.each { |attrs|
    loc = Location.find_or_create_by(code: attrs[:code])
    loc.update_attributes(attrs)
  }
  mach_bundles.each { |attrs|
    mb = MachineBundle.find_or_create_by(name: attrs[:name])
    mb.update_attributes(attrs)
  }
  worker_types.each { |attrs|
    wt = WorkerType.find_or_create_by(name: attrs[:name], code: attrs[:code], status: attrs[:status])
    wt.update_attributes(attrs)
  }
  job_titles.each { |attrs|
    jt = JobTitle.find_or_create_by(name: attrs[:name], code: attrs[:code], status: attrs[:status])
  }
end

dept_mach_bundles = [
  {:department_id => Department.find_by(:name => "BizOpti/Internal System Engineering").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle - Engineer").id},
  {:department_id => Department.find_by(:name => "BizOpti/Internal System Engineering").id, :machine_bundle_id => MachineBundle.find_by(:name => '15" Mac Bundle').id},
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
  {:department_id => Department.find_by(:name => "People & Culture-HR & Total Rewards").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
  {:department_id => Department.find_by(:name => "People & Culture-HR & Total Rewards").id, :machine_bundle_id => MachineBundle.find_by(:name => '13" Mac Bundle').id},
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
  {:department_id => Department.find_by(:name => "People & Culture-Talent Acquisition").id, :machine_bundle_id => MachineBundle.find_by(:name => "PC Bundle").id},
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
