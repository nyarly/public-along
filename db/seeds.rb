# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

depts = [
  {:name =>  "OT Facilities", :code => "000010"},
  {:name =>  "OT People and Culture", :code => "000011"},
  {:name =>  "OT Legal", :code => "000012"},
  {:name =>  "OT Finance", :code => "000013"},
  {:name =>  "OT Risk Management and Fraud", :code => "000014"},
  {:name =>  "OT Talent Acquisition", :code => "000017"},
  {:name =>  "OT Executive", :code => "000018"},
  {:name =>  "OT Finance Operations", :code => "000019"},
  {:name =>  "OT Sales - General", :code => "000020"},
  {:name =>  "OT Sales Operations", :code => "000021"},
  {:name =>  "OT Inside Sales", :code => "000025"},
  {:name =>  "OT Field Operations", :code => "000031"},
  {:name =>  "OT Customer Support", :code => "000032"},
  {:name =>  "OT Restaurant Relations Management", :code => "000033"},
  {:name =>  "OT IT Technical Services and Helpdesk", :code => "000035"},
  {:name =>  "OT IT - Engineering", :code => "000036"},
  {:name =>  "OT General Engineering", :code => "000040"},
  {:name =>  "OT Consumer Engineering", :code => "000041"},
  {:name =>  "OT Restaurant Engineering", :code => "000042"},
  {:name =>  "OT Data Center Ops", :code => "000043"},
  {:name =>  "OT Business Optimization", :code => "000044"},
  {:name =>  "OT Data Analytics", :code => "000045"},
  {:name =>  "OT General Marketing", :code => "000050"},
  {:name =>  "OT Consumer Marketing", :code => "000051"},
  {:name =>  "OT Restaurant Marketing", :code => "000052"},
  {:name =>  "OT Public Relations", :code => "000053"},
  {:name =>  "OT Product Marketing", :code => "000054"},
  {:name =>  "OT General Product Management", :code => "000060"},
  {:name =>  "OT Restaurant Product Management", :code => "000061"},
  {:name =>  "OT Consumer Product Management", :code => "000062"},
  {:name =>  "OT Design", :code => "000063"},
  {:name =>  "OT Business Development", :code => "000070"}
]

ActiveRecord::Base.transaction do
  depts.each { |attrs| Department.create(attrs) }
end

locs = [
  { :name => "OT San Francisco", :kind => "Office", :country => "US" },
  { :name => "OT Los Angeles", :kind => "Office", :country => "US" },
  { :name => "OT Denver", :kind => "Office", :country => "US" },
  { :name => "OT Chattanooga", :kind => "Office", :country => "US" },
  { :name => "OT Chicago", :kind => "Office", :country => "US" },
  { :name => "OT New York", :kind => "Office", :country => "US" },
  { :name => "OT Mexico City", :kind => "Office", :country => "MX" },
  { :name => "OT London", :kind => "Office", :country => "GB" },
  { :name => "OT Frankfurt", :kind => "Office", :country => "DE" },
  { :name => "OT Mumbai", :kind => "Office", :country => "IN" },
  { :name => "OT Tokyo", :kind => "Office", :country => "JP" },
  { :name => "OT Melbourne", :kind => "Office", :country => "AU" },
  { :name => "OT Arizona", :kind => "Remote Location", :country => "US" },
  { :name => "OT Colorado", :kind => "Remote Location", :country => "US" },
  { :name => "OT Illinois", :kind => "Remote Location", :country => "US" },
  { :name => "OT Tennessee", :kind => "Remote Location", :country => "US" },
  { :name => "OT Southern CA", :kind => "Remote Location", :country => "US" },
  { :name => "OT Minnesota", :kind => "Remote Location", :country => "US" },
  { :name => "OT Maine", :kind => "Remote Location", :country => "US" },
  { :name => "OT Georgia", :kind => "Remote Location", :country => "US" },
  { :name => "OT Canada", :kind => "Remote Location", :country => "CA" },
  { :name => "OT Washington DC", :kind => "Remote Location", :country => "US" },
  { :name => "OT Pennsylvania", :kind => "Remote Location", :country => "US" },
  { :name => "OT Oregon", :kind => "Remote Location", :country => "US" },
  { :name => "OT Wisconsin", :kind => "Remote Location", :country => "US" },
  { :name => "OT Texas", :kind => "Remote Location", :country => "US" },
  { :name => "OT Ohio", :kind => "Remote Location", :country => "US" },
  { :name => "OT Massachusetts", :kind => "Remote Location", :country => "US" },
  { :name => "OT Washington", :kind => "Remote Location", :country => "US" },
  { :name => "OT Florida", :kind => "Remote Location", :country => "US" },
  { :name => "OT Nevada", :kind => "Remote Location", :country => "US" },
  { :name => "OT New Jersey", :kind => "Remote Location", :country => "US" },
  { :name => "OT Hawaii", :kind => "Remote Location", :country => "US" },
  { :name => "OT Vermont", :kind => "Remote Location", :country => "US" },
  { :name => "OT Missouri", :kind => "Remote Location", :country => "US" },
  { :name => "OT Louisiana", :kind => "Remote Location", :country => "US" },
  { :name => "OT Michigan", :kind => "Remote Location", :country => "US" },
  { :name => "OT Ireland", :kind => "Remote Location", :country => "IE" },
  { :name => "OT North Carolina", :kind => "Remote Location", :country => "US" },
  { :name => "OT Idaho", :kind => "Remote Location", :country => "US" },
  { :name => "OT Maryland", :kind => "Remote Location", :country => "US" },
  { :name => "OT Utah", :kind => "Remote Location", :country => "US" },
  { :name => "OT Kentucky", :kind => "Remote Location", :country => "US" }
]

ActiveRecord::Base.transaction do
  locs.each { |attrs| Location.create(attrs) }
  puts :count => Location.count
end
