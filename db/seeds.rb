# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

standard_countries = [
  { name: 'Pending Assignment', iso_alpha_2_code: 'Pending Assignment'},
  { name: 'Australia', iso_alpha_2_code: 'AU', currency: Currency.find_or_create_by(name: 'Australian Dollar', iso_alpha_code: 'AUD') },
  { name: 'Canada', iso_alpha_2_code: 'CA', currency: Currency.find_or_create_by(name: 'Canadian Dollar', iso_alpha_code: 'CAD') },
  { name: 'Germany', iso_alpha_2_code: 'DE', currency: Currency.find_or_create_by(name: 'Euro', iso_alpha_code: 'EUR') },
  { name: 'Great Britain', iso_alpha_2_code: 'GB', currency: Currency.find_or_create_by(name: 'Pound Sterling', iso_alpha_code: 'GBP') },
  { name: 'Ireland', iso_alpha_2_code: 'IE', currency: Currency.find_or_create_by(name: 'Euro', iso_alpha_code: 'EUR') },
  { name: 'India', iso_alpha_2_code: 'IN', currency: Currency.find_or_create_by(name: 'Indian Rupee', iso_alpha_code: 'INR') },
  { name: 'Japan', iso_alpha_2_code: 'JP', currency: Currency.find_or_create_by(name: 'Japanese Yen', iso_alpha_code: 'JPY') },
  { name: 'Mexico', iso_alpha_2_code: 'MX', currency: Currency.find_or_create_by(name: 'Mexican Peso', iso_alpha_code: 'MXN') },
  { name: 'United States', iso_alpha_2_code: 'US', currency: Currency.find_or_create_by(name: 'United States Dollar', iso_alpha_code: 'USD') }
]

depts = [
  { name: "Facilities", code: "010000", status: "Active" },
  { name: "People & Culture-HR & Total Rewards", code: "011000", status: "Active" },
  { name: "Legal", code: "012000", status: "Active" },
  { name: "Finance", code: "013000", status: "Active" },
  { name: "Risk Management", code: "014000", status: "Active" },
  { name: "People & Culture-Talent Acquisition", code: "017000", status: "Active" },
  { name: "Executive", code: "018000", status: "Active" },
  { name: "Finance Operations", code: "019000", status: "Active" },
  { name: "Sales", code: "020000", status: "Active" },
  { name: "Sales Operations", code: "021000", status: "Active" },
  { name: "Inside Sales", code: "025000", status: "Active" },
  { name: "Field Operations", code: "031000", status: "Active" },
  { name: "Customer Support", code: "032000", status: "Active" },
  { name: "Restaurant Relations Management", code: "033000", status: "Active" },
  { name: "Tech Table", code: "035000", status: "Active" },
  { name: "Infrastructure Engineering", code: "036000", status: "Active" },
  { name: "Technology/CTO Admin", code: "040000", status: "Active" },
  { name: "Product Engineering - Front End Diner", code: "041000", status: "Active" },
  { name: "Product Engineering - Front End Restaurant", code: "042000", status: "Active" },
  { name: "Product Engineering - Back End", code: "043000", status: "Active" },
  { name: "BizOpti/Internal System Engineering", code: "044000", status: "Active" },
  { name: "Data Analytics & Experimentation", code: "045000", status: "Active" },
  { name: "Data Science", code: "046000", status: "Active" },
  { name: "Brand/General Marketing", code: "050000", status: "Active" },
  { name: "Consumer Marketing", code: "051000", status: "Active" },
  { name: "Restaurant Marketing", code: "052000", status: "Active" },
  { name: "Public Relations", code: "053000", status: "Active" },
  { name: "Product Marketing", code: "054000", status: "Active" },
  { name: "Restaurant Product Management", code: "061000", status: "Active" },
  { name: "Consumer Product Management", code: "062000", status: "Active" },
  { name: "Design", code: "063000", status: "Active" },
  { name: "Business Development", code: "070000", status: "Active" }
]

locs = [
  { name: "Leeds", kind: "Remote Location", status: "Active", code: "LD", timezone: "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" },
  { name: "Berlin", kind: "Remote Location", status: "Active", code: "BER", timezone: "(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna" },
  { name: "Birmingham", kind: "Remote Location", status: "Active", code: "BM", timezone: "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" },
  { name: "London Office", kind: "Office", status: "Active", code: "LON", timezone: "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" },
  { name: "Los Angeles Office", kind: "Office", status: "Active", code: "LOS", timezone: "(GMT-08:00) Pacific Time (US & Canada), Tijuana" },
  { name: "Massachusetts", kind: "Remote Location", status: "Active", code: "MA", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Manchester", kind: "Remote Location", status: "Active", code: "MAN", timezone: "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" },
  { name: "Maryland", kind: "Remote Location", status: "Active", code: "MD", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Maine", kind: "Remote Location", status: "Active", code: "ME", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Melbourne Office", kind: "Office", status: "Active", code: "MEL", timezone: "(GMT+10:00) Canberra, Melbourne, Sydney" },
  { name: "Michigan", kind: "Remote Location", status: "Active", code: "MI", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Minnesota", kind: "Remote Location", status: "Active", code: "MN", timezone: "(GMT-06:00) Central Time (US & Canada)" },
  { name: "Missouri", kind: "Remote Location", status: "Active", code: "MO", timezone: "(GMT-06:00) Central Time (US & Canada)" },
  { name: "Mumbai Office", kind: "Office", status: "Active", code: "MUM", timezone: "(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi" },
  { name: "Munich", kind: "Remote Location", status: "Active", code: "MUN", timezone: "(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna" },
  { name: "Mexico City Office", kind: "Office", status: "Active", code: "MXC", timezone: "(GMT-06:00) Central Time (US & Canada)" },
  { name: "North Carolina", kind: "Remote Location", status: "Active", code: "NC", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Northern California", kind: "Remote Location", status: "Active", code: "NCA", timezone: "(GMT-08:00) Pacific Time (US & Canada), Tijuana" },
  { name: "Nebraska", kind: "Remote Location", status: "Active", code: "NE", timezone: "(GMT-06:00) Central Time (US & Canada)" },
  { name: "New Jersey", kind: "Remote Location", status: "Active", code: "NJ", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Nevada", kind: "Remote Location", status: "Active", code: "NV", timezone: "(GMT-08:00) Pacific Time (US & Canada), Tijuana" },
  { name: "New York", kind: "Remote Location", status: "Active", code: "NY", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "New York City Office", kind: "Office", status: "Active", code: "NYC", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Ohio", kind: "Remote Location", status: "Active", code: "OH", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Ontario", kind: "Remote Location", status: "Active", code: "ON", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Oregon", kind: "Remote Location", status: "Active", code: "OR", timezone: "(GMT-08:00) Pacific Time (US & Canada), Tijuana" },
  { name: "Pennsylvania", kind: "Remote Location", status: "Active", code: "PA", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Powai", kind: "Remote Location", status: "Active", code: "POW", timezone: "(GMT+05:30) Chennai, Kolkata, Mumbai, New Delhi" },
  { name: "Quebec", kind: "Remote Location", status: "Active", code: "QC", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "South Carolina", kind: "Remote Location", status: "Active", code: "SC", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Southern California", kind: "Remote Location", status: "Active", code: "SCA", timezone: "(GMT-08:00) Pacific Time (US & Canada), Tijuana" },
  { name: "San Francisco Headquarters", kind: "Office", status: "Active", code: "SF", timezone: "(GMT-08:00) Pacific Time (US & Canada), Tijuana" },
  { name: "Sydney", kind: "Remote Location", status: "Active", code: "SY", timezone: "(GMT+10:00) Canberra, Melbourne, Sydney" },
  { name: "Tennessee", kind: "Remote Location", status: "Active", code: "TN", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Texas", kind: "Remote Location", status: "Active", code: "TX", timezone: "(GMT-06:00) Central Time (US & Canada)" },
  { name: "Tokyo Office", kind: "Office", status: "Active", code: "TYO", timezone: "(GMT+09:00) Osaka, Sapporo, Tokyo" },
  { name: "Utah", kind: "Remote Location", status: "Active", code: "UT", timezone: "(GMT-07:00) Mountain Time (US & Canada)" },
  { name: "Vermont", kind: "Remote Location", status: "Active", code: "VT", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Washington", kind: "Remote Location", status: "Active", code: "WA", timezone: "(GMT-08:00) Pacific Time (US & Canada), Tijuana" },
  { name: "Wisconsin", kind: "Remote Location", status: "Active", code: "WI", timezone: "(GMT-06:00) Central Time (US & Canada)" },
  { name: "Alberta", kind: "Remote Location", status: "Active", code: "AB", timezone: "(GMT-07:00) Mountain Time (US & Canada)" },
  { name: "Arizona", kind: "Remote Location", status: "Active", code: "AZ", timezone: "(GMT-07:00) Mountain Time (US & Canada)" },
  { name: "British Columbia", kind: "Remote Location", status: "Active", code: "BC", timezone: "(GMT-08:00) Pacific Time (US & Canada), Tijuana" },
  { name: "Bristol", kind: "Remote Location", status: "Active", code: "BZ", timezone: "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" },
  { name: "Concord Distribution Center", kind: "Remote Location", status: "Active", code: "CDC", timezone: "(GMT-08:00) Pacific Time (US & Canada), Tijuana" },
  { name: "Chicago Office", kind: "Office", status: "Active", code: "CHI", timezone: "(GMT-06:00) Central Time (US & Canada)" },
  { name: "Colorado", kind: "Remote Location", status: "Active", code: "CO", timezone: "(GMT-07:00) Mountain Time (US & Canada)" },
  { name: "CONTRACT", kind: "Remote Location", status: "Active", code: "CONTR", timezone: "(GMT-08:00) Pacific Time (US & Canada), Tijuana" },
  { name: "Corby", kind: "Remote Location", status: "Active", code: "COR", timezone: "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" },
  { name: "Cancun", kind: "Remote Location", status: "Active", code: "CUN", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Washington", kind: "Remote Location", status: "Active", code: "DC", timezone: "DC (GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Denver Contact Center", kind: "Remote Location", status: "Active", code: "DCC", timezone: "(GMT-07:00) Mountain Time (US & Canada)" },
  { name: "Denver Office", kind: "Office", status: "Active", code: "DEN", timezone: "(GMT-07:00) Mountain Time (US & Canada)" },
  { name: "Denver CSR", kind: "Remote Location", status: "Active", code: "DENCS", timezone: "(GMT-07:00) Mountain Time (US & Canada)" },
  { name: "Dundee", kind: "Remote Location", status: "Active", code: "DND", timezone: "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" },
  { name: "Edinburgh", kind: "Remote Location", status: "Active", code: "EB", timezone: "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" },
  { name: "Florida", kind: "Remote Location", status: "Active", code: "FL", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Frankfurt Office", kind: "Office", status: "Active", code: "FRA", timezone: "(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna" },
  { name: "Georgia", kind: "Remote Location", status: "Active", code: "GA", timezone: "(GMT-05:00) Eastern Time (US & Canada)" },
  { name: "Glasgow", kind: "Remote Location", status: "Active", code: "GLA", timezone: "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" },
  { name: "Hamburg", kind: "Remote Location", status: "Active", code: "HAM", timezone: "(GMT+01:00) Amsterdam, Berlin, Bern, Rome, Stockholm, Vienna" },
  { name: "Hawaii", kind: "Remote Location", status: "Active", code: "HI", timezone: "(GMT-10:00) Hawaii" },
  { name: "Idaho", kind: "Remote Location", status: "Active", code: "ID", timezone: "(GMT-07:00) Mountain Time (US & Canada)" },
  { name: "Illinois", kind: "Remote Location", status: "Active", code: "IL", timezone: "(GMT-06:00) Central Time (US & Canada)" },
  { name: "Ireland", kind: "Remote Location", status: "Active", code: "IRL", timezone: "(GMT) Greenwich Mean Time : Dublin, Edinburgh, Lisbon, London" },
  { name: "Kentucky", kind: "Remote Location", status: "Active", code: "KY", timezone: "(GMT-06:00) Central Time (US & Canada)" },
  { name: "Louisiana", kind: "Remote Location", status: "Active", code: "LA", timezone: "(GMT-06:00) Central Time (US & Canada)" },
  { code: "NSW", kind: "Remote Location", status: "Active", name: "New South Wales", timezone: "(GMT+10:00) Canberra, Melbourne, Sydney" },
  { code: "QLD", kind: "Remote Location", status: "Active", name: "Queensland", timezone: "(GMT+10:00) Canberra, Melbourne, Sydney" },
  { code: "VIC", kind: "Remote Location", status: "Active", name: "Victoria", timezone: "(GMT+10:00) Canberra, Melbourne, Sydney" }
]

mach_bundles = [
  { name: 'PC Bundle', description: 'T460, 27" Asus Monitor' },
  { name: '13" Mac Bundle', description: '13" MacBook Air, 27" Asus Monitor' },
  { name: 'PC Bundle - Remote', description: 'T460' },
  { name: '13" Mac Bundle - Remote', description: '13" MacBook Air' },
  { name: 'PC Bundle - Engineer', description: 'T460 (engineering), 27" Asus Monitor, Accessories' },
  { name: '15" Mac Bundle', description: '15" MacBook Pro, 27" Asus Monitor' },
  { name: 'Customer Support', description: 'T460, 2x 24" Monitors' },
  { name: 'Special Equipment Bundle', description: 'Please describe in notes to Tech Table below' },
  { name: 'No Equipment Needed', description: 'Tech Table will not provision any equipment' },
  { name: 'Contingent Worker Mac', description: 'Mac laptop, model depending on availability' },
  { name: 'Contingent Worker PC', description: 'PC laptop, model depending on availability' }
]

ActiveRecord::Base.transaction do
  standard_countries.each { |attrs|
    country = Country.find_or_create_by(name: attrs[:name], iso_alpha_2_code: attrs[:iso_alpha_2_code])
    country.update_attributes(attrs)
  }
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
end

def populate_location_address(name, country_code)
  location = Location.find_by(name: name)
  country = Country.find_by(iso_alpha_2_code: country_code)

  if location.present? && country.present?
    location.build_address(country: country).save!
  end
end

ActiveRecord::Base.transaction do
  populate_location_address('Tokyo Office', 'JP')

  ger = ['Berlin', 'Frankfurt Office', 'Munich']
  ger.each { |city| populate_location_address(city, 'DE') }

  gb = [
    'Corby',
    'Birmingham',
    'Bristol',
    'Edinburgh',
    'Glasgow',
    'Leeds',
    'London Office',
    'Manchester'
  ]

  gb.each { |city| populate_location_address(city, 'GB') }

  india = ['Dundee', 'Mumbai Office', 'Powai']
  india.each { |city| populate_location_address(city, 'IN') }

  aust = ['Melbourne Office', 'New South Wales', 'Queensland', 'Sydney', 'Victoria']
  aust.each { |city| populate_location_address(city, 'AU') }

  mex = ['Mexico City Office', 'Cancun']
  mex.each { |city| populate_location_address(city, 'MX') }

  can = ['Alberta', 'British Columbia', 'Ontario', 'Quebec']
  can.each { |city| populate_location_address(city, 'CA') }

  us = [
    'Arizona',
    'Concord Distribution Center',
    'Chicago Office',
    'Colorado',
    'CONTRACT',
    'Washington',
    'Denver Contact Center',
    'Denver Office',
    'Denver CSR',
    'Florida',
    'Georgia',
    'Hamburg',
    'Hawaii',
    'Idaho',
    'Illinois',
    'Ireland',
    'Kentucky',
    'Los Angeles Office',
    'Louisiana',
    'Massachusetts',
    'Maryland',
    'Maine',
    'Michigan',
    'Minnesota',
    'Missouri',
    'North Carolina',
    'Northern California',
    'Nebraska',
    'New Jersey',
    'Nevada',
    'New York',
    'New York City Office',
    'Ohio',
    'Oregon',
    'Pennsylvania',
    'South Carolina',
    'Southern California',
    'San Francisco Headquarters',
    'Tennessee',
    'Texas',
    'Utah',
    'Vermont',
    'Washington',
    'Wisconsin'
  ]

  us.each { |city| populate_location_address(city, 'US') }
end

dept_mach_bundles = [
  { department_id: Department.find_by(name: "BizOpti/Internal System Engineering").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Engineer").id },
  { department_id: Department.find_by(name: "BizOpti/Internal System Engineering").id, machine_bundle_id: MachineBundle.find_by(name: '15" Mac Bundle').id },
  { department_id: Department.find_by(name: "Brand/General Marketing").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Brand/General Marketing").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Business Development").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Business Development").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Consumer Marketing").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Consumer Marketing").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Consumer Product Management").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Engineer").id },
  { department_id: Department.find_by(name: "Consumer Product Management").id, machine_bundle_id: MachineBundle.find_by(name: '15" Mac Bundle').id },
  { department_id: Department.find_by(name: "Customer Support").id, machine_bundle_id: MachineBundle.find_by(name: 'Customer Support').id },
  { department_id: Department.find_by(name: "Data Analytics & Experimentation").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Engineer").id },
  { department_id: Department.find_by(name: "Data Analytics & Experimentation").id, machine_bundle_id: MachineBundle.find_by(name: '15" Mac Bundle').id },
  { department_id: Department.find_by(name: "Data Science").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Engineer").id },
  { department_id: Department.find_by(name: "Data Science").id, machine_bundle_id: MachineBundle.find_by(name: '15" Mac Bundle').id },
  { department_id: Department.find_by(name: "Design").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Engineer").id },
  { department_id: Department.find_by(name: "Design").id, machine_bundle_id: MachineBundle.find_by(name: '15" Mac Bundle').id },
  { department_id: Department.find_by(name: "Executive").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Executive").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Facilities").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Facilities").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Field Operations").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Field Operations").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Field Operations").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Remote").id },
  { department_id: Department.find_by(name: "Field Operations").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle - Remote').id },
  { department_id: Department.find_by(name: "Finance").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Finance Operations").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Infrastructure Engineering").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Engineer").id },
  { department_id: Department.find_by(name: "Infrastructure Engineering").id, machine_bundle_id: MachineBundle.find_by(name: '15" Mac Bundle').id },
  { department_id: Department.find_by(name: "Inside Sales").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Legal").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "People & Culture-HR & Total Rewards").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "People & Culture-HR & Total Rewards").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Product Engineering - Front End Diner").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Engineer").id },
  { department_id: Department.find_by(name: "Product Engineering - Front End Diner").id, machine_bundle_id: MachineBundle.find_by(name: '15" Mac Bundle').id },
  { department_id: Department.find_by(name: "Product Engineering - Front End Restaurant").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Engineer").id },
  { department_id: Department.find_by(name: "Product Engineering - Front End Restaurant").id, machine_bundle_id: MachineBundle.find_by(name: '15" Mac Bundle').id },
  { department_id: Department.find_by(name: "Product Engineering - Back End").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Engineer").id },
  { department_id: Department.find_by(name: "Product Engineering - Back End").id, machine_bundle_id: MachineBundle.find_by(name: '15" Mac Bundle').id },
  { department_id: Department.find_by(name: "Product Marketing").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Product Marketing").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Public Relations").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Public Relations").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Restaurant Marketing").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Restaurant Marketing").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Restaurant Product Management").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Restaurant Product Management").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Restaurant Relations Management").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Restaurant Relations Management").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Risk Management").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Risk Management").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Sales").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Sales").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Sales").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Remote").id },
  { department_id: Department.find_by(name: "Sales").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle - Remote').id },
  { department_id: Department.find_by(name: "Sales Operations").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Sales Operations").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle').id },
  { department_id: Department.find_by(name: "Sales Operations").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Remote").id },
  { department_id: Department.find_by(name: "Sales Operations").id, machine_bundle_id: MachineBundle.find_by(name: '13" Mac Bundle - Remote').id },
  { department_id: Department.find_by(name: "People & Culture-Talent Acquisition").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle").id },
  { department_id: Department.find_by(name: "Tech Table").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Engineer").id },
  { department_id: Department.find_by(name: "Tech Table").id, machine_bundle_id: MachineBundle.find_by(name: '15" Mac Bundle').id },
  { department_id: Department.find_by(name: "Technology/CTO Admin").id, machine_bundle_id: MachineBundle.find_by(name: "PC Bundle - Engineer").id },
  { department_id: Department.find_by(name: "Technology/CTO Admin").id, machine_bundle_id: MachineBundle.find_by(name: '15" Mac Bundle').id },
]

ActiveRecord::Base.transaction do
  dept_mach_bundles.each { |attrs| DeptMachBundle.find_or_create_by(attrs) }
  Department.find_each { |d|
    ["No Equipment Needed", "Special Equipment Bundle", "Contingent Worker Mac", "Contingent Worker PC"].each do |name|
      mb = MachineBundle.find_by(name: name)
      d.machine_bundles << mb unless d.machine_bundles.include?(mb)
    end
  }
end
