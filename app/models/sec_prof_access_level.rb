class SecProfAccessLevel < ActiveRecord::Base
  belongs_to :security_profile
  belongs_to :access_level
end
