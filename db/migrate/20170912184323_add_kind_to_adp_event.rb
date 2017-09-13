class AddKindToAdpEvent < ActiveRecord::Migration
  def change
    add_column :adp_events, :kind, :string
  end
end
