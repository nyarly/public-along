class Role::Helpdesk < Role::Basic
  Role.register 'Helpdesk', self

  def set_abilities(ability)
    super

    # ability.can :read, PermissionRequest
    # ability.can :read, EquipmentRequest
  end
end
