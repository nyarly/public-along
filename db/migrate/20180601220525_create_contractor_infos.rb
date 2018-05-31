class CreateContractorInfos < ActiveRecord::Migration
  def change
    create_table :contractor_infos do |t|
      t.string :req_or_po_number
      t.string :legal_approver
      t.references :emp_transaction, null: false

      t.timestamps null: false
    end
  end
end
