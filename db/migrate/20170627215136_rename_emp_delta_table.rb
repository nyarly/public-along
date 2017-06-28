class RenameEmpDeltaTable < ActiveRecord::Migration
  def change
    rename_table :emp_delta, :emp_deltas
  end
end
