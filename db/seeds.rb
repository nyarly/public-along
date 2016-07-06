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
