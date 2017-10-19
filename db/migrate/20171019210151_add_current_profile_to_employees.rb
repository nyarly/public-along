class AddCurrentProfileToEmployees < ActiveRecord::Migration
  def change
    add_reference :employees, :current_profile, index: true
  end
end
