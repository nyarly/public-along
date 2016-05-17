class AddActiveDirectoryLastUpdatedToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :ad_updated_at, :datetime
  end
end
