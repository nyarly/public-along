require 'rails_helper'

module AuthorizationHelpers

  def should_authorize(action, subject)
    expect(controller).to receive(:authorize!).with(action, subject).and_return('passed!')
  end

  def should_not_authorize(action, subject)
    expect(controller).to receive(:authorize!).with(action, subject).and_raise(CanCan::AccessDenied.new("Not authorized", action, subject))
  end

end

RSpec.configure do |config|
  config.include AuthorizationHelpers, :type => :controller
end
