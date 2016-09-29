require 'class_registry'
class Role
  include ClassRegistry
  def self.registrar; Role; end

  def self.list(user)
    list = []
    user.role_names.each do |role_name|
      role = registry[role_name].new.tap { |r| r.user = user }
      list << role
    end
    list
  end

  def self.users
    User.where('role_names LIKE ?', "%#{registrar.registry_key(self)}%")
  end


  def role_names
    user.role_names
  end


  attr_accessor :user

  Dir[File.dirname(__FILE__) + '/role/*.rb'].each { |file| require file }
end
