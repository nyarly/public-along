class CreateParentOrgs < ActiveRecord::Migration
  def change
    create_table :parent_orgs do |t|
      t.string :name
      t.string :code

      t.timestamps null: false
    end
  end
end
