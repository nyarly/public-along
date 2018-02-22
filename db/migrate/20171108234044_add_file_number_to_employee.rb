class AddFileNumberToEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :payroll_file_number, :string
    add_column :employees, :home_country_code, :string
  end
end
