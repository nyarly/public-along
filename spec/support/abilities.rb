RSpec.shared_examples "role abilities" do |klass, permitted_abilities|
  full_abilities = [:manage, :create, :read, :update, :destroy]
  if permitted_abilities.include? :manage
    permitted_abilities = full_abilities
    restricted_abilities = []
  else
    restricted_abilities = full_abilities - permitted_abilities
  end

  context "for #{klass}" do
    subject(:ability) { Ability.new(user) }

    permitted_abilities.each do |pa|
      it { expect(ability).to be_able_to pa, klass }
    end

    restricted_abilities.each do |ra|
      it { expect(ability).to_not be_able_to ra, klass }
    end
  end
end
