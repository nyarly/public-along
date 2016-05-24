# workday-integration
Takes file dumps from OT Workday and automates user creation/modification in OT Active Directory.

## Getting started
- Clone repo.
- In config/ create a database.yml file, copy database.yml.example to it and procure the necessary credentials. Do the same for secrets.yml.
- From command line run (Assuming that you have an ubuntu vm set up for the db)
`rake db create`
`rake db migrate`
`rails server`
- In web browser, go to 'localhost:3000/users/sign_in'
- Sign in using test creds u:t999 p:Password1
- To sign out, go to 'localhost:3000/users/sign_out'

## TODO
- Remove TempController and views when we have real views
