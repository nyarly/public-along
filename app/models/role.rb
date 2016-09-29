require 'class_registry'
class Role
  include ClassRegistry
  def self.registrar; Role; end

  def self.list(user)
    list = []
    user.role_name.each do |role_name|
      registry[role_name].new.tap do |role|
        role.user = user
      end
      list << registry[role_name]
    end
    puts list
    list
  end

  def self.users
    User.where(:role_name => registrar.registry_key(self))
  end


  def role_name
    user.role_name
  end


  attr_accessor :user

  Dir[File.dirname(__FILE__) + '/role/*.rb'].each { |file| require file }
end
