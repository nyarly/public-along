class Ability
  include CanCan::Ability

  def initialize(user)
    if user.present?
      user.roles.each do |role|
        role.set_abilities(self)
      end

      # add common abilies to logged_in users
    else
      # add common abilities to public users here
    end
  end
end
