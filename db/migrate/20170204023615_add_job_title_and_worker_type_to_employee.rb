class AddJobTitleAndWorkerTypeToEmployee < ActiveRecord::Migration
  def change
    add_column :employees, :worker_type_id, :integer
    add_column :employees, :job_title_id, :integer
  end
end
