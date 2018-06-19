class AddPersonalEmailToEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :personal_email, :string
  end
end
