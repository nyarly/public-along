class AddLegalFirstNameToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :legal_first_name, :string
  end
end
