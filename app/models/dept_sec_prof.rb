class DeptSecProf < ActiveRecord::Base
  belongs_to :department
  belongs_to :security_profile
end
