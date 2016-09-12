class CreateOffboardingInfos < ActiveRecord::Migration
  def change
    create_table :offboarding_infos do |t|
      t.integer :employee_id
      t.integer :emp_transaction_id
      t.boolean :archive_data
      t.boolean :replacement_hired
      t.integer :forward_email_id
      t.integer :reassign_salesforce_id
      t.integer :transfer_google_docs_id

      t.timestamps null: false
    end
  end
end
