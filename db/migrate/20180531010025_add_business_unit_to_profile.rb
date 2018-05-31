class AddBusinessUnitToProfile < ActiveRecord::Migration
  def change
    add_reference :profiles, :business_unit
  end
end
