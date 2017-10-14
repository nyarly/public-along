class RenameManagerIdOnProfiles < ActiveRecord::Migration
  def change
    rename_column :profiles, :manager_id, :manager_adp_employee_id
  end
end
