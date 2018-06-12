class RemoveCompanyFromProfile < ActiveRecord::Migration
  def change
    remove_column :profiles, :company, :string
  end
end
