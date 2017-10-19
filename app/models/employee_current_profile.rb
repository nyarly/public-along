class EmployeeCurrentProfile < ActiveRecord::Base
  belongs_to :employee
  belongs_to :profile

end
