class DeptMachBundle < ActiveRecord::Base
  belongs_to :department
  belongs_to :machine_bundle
end
