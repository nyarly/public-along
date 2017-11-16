# Mezzo
Mezzo is a middleware tool that connects worker and organization data from ADP with downstream systems, including Active Directory. Mezzo also provisions a number of other systems with worker data and automates onboarding and offboarding procedures.

User and technical documentation can be found on the [wiki](https://wiki.otcorp.opentable.com/display/NETWORKOPS/Mezzo+User+Management+Tool).

## Getting started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites
- Install VirtualBox.
- Fork [OpenTable's Puppet modules](https://github.com/opentable/puppet-modules).
- Clone your forked `puppet-modules` repository locally.

### Installing

- Clone the Mezzo repo into `puppet-modules/dev-environment/shared`.
- In the `mezzo` root directory `touch config/database.yml config/secrets.yml`.
- Obtain the credentials necessary for the project, based on the `database.yml.example` and `secrets.yml.example` files.
- Create your Mezzo Vagrant configuration with `touch puppet-modules/dev-environment/vagrant.yml` and `touch environments/vagrant/manifests/nodes.pp`.

vagrant.yml
```
---
master:
  bundle_mount_hack: true
  puppetdb: true

ubuntu14:
  number_of_boxes: 1
  expand_root_filesystem: yes
```


nodes.pp
```
node 'ubuntu1404-2.vagrant.local' {
  include ::roles::mezzo
}
```

- In the root puppet-modules directory run `bundle exec librarian-puppet install`
- `cd dev-environment`
- To bring up the PuppetMaster with Vagrant, `vagrant up`
- `cd ubuntu14-04`
- To bring up the Ubuntu14 node, `vagrant up`
- `vagrant ssh` into the Vagrant box and run `puppet-agent -t`
- As root user: `vim /etc/postgresql/9.5/main/pg_hba.conf`.
- At line 5 add `host all postgres 0.0.0.0/0 trust`, save and exit vim.
- `service postgresql restart` and exit the Vagrant box.
- In the Mezzo root directory, install gems, create, migrate, and seed the database:
```
bundle install
rake db:create
rake db:migrate
rake db:seed
```
- In a web browser, go to 'localhost:3000/users/sign_in'.

### Running the tests

`bundle exec rake spec` or `bundle exec rspec spec` will run the full test suite.

## Environments

Mezzo staging is at `https://mezzo.otenv.com/`.
Mezzo production is at `https://mezzo.ot.tools/`.

## Deployment

Mezzo uses Capistrano to deploy.

- To deploy staging, merge the `master` branch to the `staging` branch, push the changes to GitHub, and run `cap staging deploy`.
- To deploy production, merge the `master` branch to the `production` branch, push the changes to GitHub, and run `cap production deploy`.

## Questions

Direct questions, suggestions, or bug reports to the Mezzo team or file a Zendesk ticket with TechTable.

