BASE = "ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"
# BASE = "ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com"

OUS = {
  "ou=Accounting," => { :department => ["OT Finance", "OT Finance Operations"], :country => ["US", "CA", "MX", "AU"] },
  "ou=Finance,ou=EU," => { :department => ["OT Finance", "OT Finance Operations"], :country => ["GB", "DE"] },
  "ou=Sales," => { :department => ["OT Sales - General", "OT Sales Operations", "OT Inside Sales", "OT Restaurant Relations Management"], :country => ["US", "CA", "MX", "AU"] },
  "ou=UK Sales,ou=EU," => { :department => ["OT Sales - General", "OT Sales Operations", "OT Inside Sales", "OT Restaurant Relations Management"], :country => ["GB", "DE"] },
  "ou=Field OPS," => { :department => ["OT Field Operations"], :country => ["US", "CA", "MX", "AU"] },
  "ou=Field OPS,ou=EU," => { :department => ["OT Field Operations"], :country => ["GB", "DE"] },
  "ou=Executive," => { :department => ["OT Executive"], :country => ["US"]},
  "ou=IT," => { :department => ["OT IT Technical Services & Helpdesk", "OT IT - Engineering", "OT Data Center Ops"], :country => ["US"] },
  "ou=IT,ou=EU," => { :department => ["OT IT Technical Services & Helpdesk", "OT IT - Engineering", "OT Data Center Ops"], :country => ["GB"] },
  "ou=Marketing," => { :department => ["OT General Marketing", "OT Consumer Marketing", "OT Restaurant Marketing", "OT Public Relations", "OT Product Marketing"], :country => ["US"] },
  "ou=Marketing,ou=EU," => { :department => ["OT General Marketing", "OT Consumer Marketing", "OT Restaurant Marketing", "OT Public Relations", "OT Product Marketing"], :country => ["GB"] },
  "ou=Engineering," => { :department => ["OT General Engineering", "OT Consumer Engineering", "OT Restaurant Engineering", "OT Business Optimization", "OT Data Analytics"], :country => ["US", "AU"] },
  "ou=Engineering,ou=EU," => { :department => ["OT General Engineering", "OT Consumer Engineering", "OT Restaurant Engineering", "OT Business Optimization", "OT Data Analytics"], :country => ["GB"] },
  "ou=People and Culture," => { :department => ["OT People and Culture", "OT Facilities"], :country => ["US", "AU"] },
  "ou=HR,ou=EU," => { :department => ["OT People and Culture", "OT Facilities"], :country => ["GB"] },
  "ou=Legal," => { :department => ["OT Legal", "OT Risk Management & Fraud"], :country => ["US"] },
  "ou=Product," => { :department => ["OT General Product Management", "OT Consumer Product Management", "OT Restaurant Product Management", "OT Design", "OT Business Development"], :country => ["US", "GB", "AU"] },
  "ou=SRP," => { :department => ["Tier 1 Support - SRP"], :country => ["US", "CA", "MX"] },
  "ou=Apollo Blake," => { :department => ["Tier 1 Support - Apollo Blake"], :country => ["US", "DE", "IE"] },
  "ou=Customer Support," => { :department => ["OT Customer Support"], :country => ["US", "AU"] },
  "ou=Operations,ou=EU," => { :department => ["OT Customer Support"], :country => ["GB"] },
  "ou=Japan," => { :department => ["OT Finance", "OT Finance Operations", "OT Sales - General", "OT Sales Operations", "OT Inside Sales", "OT Restaurant Relations Management", "OT Field Operations", "OT General Marketing", "OT Consumer Marketing", "OT Restaurant Marketing", "OT Public Relations", "OT Product Marketing", "OT Customer Support"], :country => ["JP"] }
}
