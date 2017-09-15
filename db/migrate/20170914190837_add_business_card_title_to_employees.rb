class AddBusinessCardTitleToEmployees < ActiveRecord::Migration
  def change
    add_column :employees, :business_card_title, :string, :limit => 150
  end
end
