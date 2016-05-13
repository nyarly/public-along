BASE = "ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"
# BASE = "ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"

OUS = {
  "ou=Accounting," => { :department => ["OT Finance", "OT Finance Operations"], :country => ["US", "Canada", "Mexico", "Australia"] },
  "ou=Finance,ou=EU," => { :department => ["OT Finance", "OT Finance Operations"], :country => ["UK", "Germany"] },
  "ou=Sales," => { :department => ["OT Sales - General", "OT Sales Operations", "OT Inside Sales", "OT Restaurant Relations Management"], :country => ["US", "Canada", "Mexico", "Australia"] },
  "ou=UK Sales,ou=EU," => { :department => ["OT Sales - General", "OT Sales Operations", "OT Inside Sales", "OT Restaurant Relations Management"], :country => ["UK", "Germany"] },
  "ou=Field OPS," => { :department => ["OT Field Operations"], :country => ["US", "Canada", "Mexico", "Australia"] },
  "ou=Field OPS,ou=EU," => { :department => ["OT Field Operations"], :country => ["UK", "Germany"] },
  "ou=Executive," => { :department => ["OT Executive"], :country => ["US"]},
  "ou=IT," => { :department => ["OT IT Technical Services & Helpdesk", "OT IT - Engineering", "OT Data Center Ops"], :country => ["US"] },
  "ou=IT,ou=EU," => { :department => ["OT IT Technical Services & Helpdesk", "OT IT - Engineering", "OT Data Center Ops"], :country => ["UK"] },
  "ou=Marketing," => { :department => ["OT General Marketing", "OT Consumer Marketing", "OT Restaurant Marketing", "OT Public Relations", "OT Product Marketing"], :country => ["US"] },
  "ou=Marketing,ou=EU," => { :department => ["OT General Marketing", "OT Consumer Marketing", "OT Restaurant Marketing", "OT Public Relations", "OT Product Marketing"], :country => ["UK"] },
  "ou=Engineering," => { :department => ["OT General Engineering", "OT Consumer Engineering", "OT Restaurant Engineering", "OT Business Optimization", "OT Data Analytics"], :country => ["US", "Australia"] },
  "ou=Engineering,ou=EU," => { :department => ["OT General Engineering", "OT Consumer Engineering", "OT Restaurant Engineering", "OT Business Optimization", "OT Data Analytics"], :country => ["UK"] },
  "ou=People and Culture," => { :department => ["OT People and Culture", "OT Facilities"], :country => ["US", "Australia"] },
  "ou=HR,ou=EU," => { :department => ["OT People and Culture", "OT Facilities"], :country => ["UK"] },
  "ou=Legal," => { :department => ["OT Legal", "OT Risk Management & Fraud"], :country => ["US"] },
  "ou=Product," => { :department => ["OT General Product Management", "OT Consumer Product Management", "OT Restaurant Product Management", "OT Design", "OT Business Development"], :country => ["US", "UK", "Australia"] },
  "ou=SRP," => { :department => ["Tier 1 Support - SRP"], :country => ["US", "Canada", "Mexico"] },
  "ou=Apollo Blake," => { :department => ["Tier 1 Support - Apollo Blake"], :country => ["US", "Germany", "Ireland"] },
  "ou=Customer Support," => { :department => ["OT Customer Support"], :country => ["US", "Australia"] },
  "ou=Operations,ou=EU," => { :department => ["OT Customer Support"], :country => ["UK"] },
  "ou=Japan," => { :department => ["OT Finance", "OT Finance Operations", "OT Sales - General", "OT Sales Operations", "OT Inside Sales", "OT Restaurant Relations Management", "OT Field Operations", "OT General Marketing", "OT Consumer Marketing", "OT Restaurant Marketing", "OT Public Relations", "OT Product Marketing", "OT Customer Support"], :country => ["Japan"] }
}