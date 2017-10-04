class AddRequestStatusToEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :request_status, :string
  end
end
