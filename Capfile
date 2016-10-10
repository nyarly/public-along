require "capistrano/setup"
require "capistrano/deploy"
require "capistrano/rails"
require "capistrano/bundler"
require "capistrano/rbenv"
require "capistrano/puma"
require "capistrano/sidekiq"

require "whenever/capistrano"

Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
