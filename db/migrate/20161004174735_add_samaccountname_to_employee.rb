class AddSamaccountnameToEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :sam_account_name, :string
  end
end
