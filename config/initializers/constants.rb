SECRETS = Rails.application.secrets

OUS = {
  "ou=Accounting,ou=Users," => { :department => ["Finance", "Finance Operations"], :country => ["US", "CA", "MX", "AU", "IN"] },
  "ou=Finance,ou=EU,ou=Users," => { :department => ["Finance", "Finance Operations"], :country => ["GB", "DE"] },
  "ou=Sales,ou=Users," => { :department => ["Sales", "Sales Operations", "Inside Sales", "Restaurant Relations Management"], :country => ["US", "CA", "MX", "AU"] },
  "ou=UK Sales,ou=EU,ou=Users," => { :department => ["Sales", "Sales Operations", "Inside Sales", "Restaurant Relations Management"], :country => ["GB", "IE", "DE"] },
  "ou=DE Sales,ou=EU,ou=Users," => { :department => ["Sales", "Sales Operations", "Inside Sales", "Restaurant Relations Management"], :country => ["DE"] },
  "ou=Field OPS,ou=Users," => { :department => ["Field Operations"], :country => ["US", "CA", "MX", "AU"] },
  "ou=Field OPS,ou=EU,ou=Users," => { :department => ["Field Operations"], :country => ["GB", "DE", "IE"] },
  "ou=Executive,ou=Users," => { :department => ["Executive"], :country => ["US", "JP"]},
  "ou=IT,ou=Users," => { :department => ["Tech Table", "Infrastructure Engineering"], :country => ["US", "IN"] },
  "ou=IT,ou=EU,ou=Users," => { :department => ["Tech Table", "Infrastructure Engineering"], :country => ["GB"] },
  "ou=Marketing,ou=Users," => { :department => ["Brand/General Marketing", "Consumer Marketing", "Restaurant Marketing", "Public Relations", "Product Marketing"], :country => ["US", "AU"] },
  "ou=Marketing,ou=EU,ou=Users," => { :department => ["Brand/General Marketing", "Consumer Marketing", "Restaurant Marketing", "Public Relations", "Product Marketing"], :country => ["GB", "DE", "IE"] },
  "ou=Engineering,ou=Users," => { :department => ["Technology/CTO Admin", "Product Engineering - Front End Diner", "Product Engineering - Front End Restaurant", "Product Engineering - Back End", "BizOpti/Internal Systems Engineering", "Data Analytics & Experimentation", "Data Science"], :country => ["US", "AU", "IN"] },
  "ou=Engineering,ou=EU,ou=Users," => { :department => ["Technology/CTO Admin", "Product Engineering - Front End Diner", "Product Engineering - Front End Restaurant", "Product Engineering - Back End", "BizOpti/Internal Systems Engineering", "Data Analytics & Experimentation", "Data Science"], :country => ["GB"] },
  "ou=People and Culture,ou=Users," => { :department => ["People and Culture", "Talent Acquisition", "Facilities"], :country => ["US", "AU"] },
  "ou=HR,ou=EU,ou=Users," => { :department => ["People and Culture", "Talent Acquisition", "Facilities"], :country => ["GB"] },
  "ou=Legal,ou=Users," => { :department => ["Legal", "Risk Management"], :country => ["US"] },
  "ou=Product,ou=Users," => { :department => ["Consumer Product Management", "Restaurant Product Management", "Business Development"], :country => ["US", "GB", "DE", "AU"] },
  "ou=SRP,ou=Users," => { :department => ["Tier 1 Support - SRP"], :country => ["US", "CA", "MX"] },
  "ou=Apollo Blake,ou=Users," => { :department => ["Tier 1 Support - Apollo Blake"], :country => ["US", "DE", "IE"] },
  "ou=Customer Support,ou=Users," => { :department => ["Customer Support"], :country => ["US", "AU"] },
  "ou=Operations,ou=EU,ou=Users," => { :department => ["Customer Support"], :country => ["GB"] },
  "ou=Japan,ou=Users," => { :department => ["Finance", "Finance Operations", "Sales", "Sales Operations", "Inside Sales", "Restaurant Relations Management", "Field Operations", "Brand/General Marketing", "Consumer Marketing", "Restaurant Marketing", "Public Relations", "Product Marketing", "Customer Support"], :country => ["JP"] }
}

# In AD, this value indicates that the account never expires
NEVER_EXPIRES = "9223372036854775807"

# For tests and sample data
IMAGE = "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"
