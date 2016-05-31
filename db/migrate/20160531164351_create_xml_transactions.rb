class CreateXmlTransactions < ActiveRecord::Migration
  def change
    create_table :xml_transactions do |t|
      t.string :name
      t.string :checksum

      t.timestamps null: false
    end
  end
end
