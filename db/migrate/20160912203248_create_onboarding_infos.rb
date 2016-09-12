class CreateOnboardingInfos < ActiveRecord::Migration
  def change
    create_table :onboarding_infos do |t|
      t.integer :employee_id
      t.integer :emp_transaction_id
      t.integer :buddy_id
      t.boolean :cw_email
      t.boolean :cw_google_membership

      t.timestamps null: false
    end
  end
end
