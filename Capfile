require "capistrano/setup"
require "capistrano/deploy"
require "capistrano/rails"
require "capistrano/bundler"
require "capistrano/rbenv"
require "capistrano/puma"

set :whenever_environment, defer { stage }
require "whenever/capistrano"

Dir.glob("lib/capistrano/tasks/*.rake").each { |r| import r }
