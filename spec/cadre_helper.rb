require 'cadre/rspec3'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  if config.formatters.empty?
    config.add_formatter(:progress)
  end
  config.add_formatter(Cadre::RSpec3::NotifyOnCompleteFormatter)
  config.add_formatter(Cadre::RSpec3::QuickfixFormatter)
end
