class CreateJobTitles < ActiveRecord::Migration
  def change
    create_table :job_titles do |t|
      t.string :name
      t.string :code
      t.string :status

      t.timestamps null: false
    end
  end
end
