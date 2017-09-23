# require 'rails_helper'

# describe EmpLdapEntry, type: :model do
#   let(:manager) { FactoryGirl.create(:regular_employee) }

#   context "regular worker" do
#     let(:employee) { FactoryGirl.create(:employee,
#                      first_name: "Bob",
#                      last_name: "Barker") }
#     let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
#                      employee: employee,
#                      manager_id: manager.employee_id) }

#     it "should create a cn" do
#       expect(employee.cn).to eq("Bob Barker")
#     end

#     it "should create an fn" do
#       expect(employee.fn).to eq("Barker, Bob")
#     end

#     it "should find the correct ou" do
#       expect(employee.ou).to eq("ou=Operations,ou=EU,ou=Users,")
#     end

#     it "should create a dn" do
#       expect(employee.dn).to eq("cn=Bob Barker,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com")
#     end

#     it "should set the correct account expiry" do
#       expect(employee.generated_account_expires).to eq("9223372036854775807")
#     end

#     it "should set the correct address" do
#       expect(employee.generated_address).to be_nil
#     end

#     it "should create attr hash" do
#       expect(employee.ad_attrs).to eq(
#         {
#           cn: "Bob Barker",
#           dn: "cn=Bob Barker,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
#           objectclass: ["top", "person", "organizationalPerson", "user"],
#           givenName: "Bob",
#           sn: "Barker",
#           sAMAccountName: employee.sam_account_name,
#           displayName: employee.cn,
#           userPrincipalName: employee.generated_upn,
#           manager: manager.dn,
#           mail: employee.email,
#           unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
#           co: employee.location.country,
#           accountExpires: employee.generated_account_expires,
#           title: employee.job_title.name,
#           description: employee.job_title.name,
#           employeeType: employee.worker_type.name,
#           physicalDeliveryOfficeName: employee.location.name,
#           department: employee.department.name,
#           employeeID: employee.employee_id,
#           telephoneNumber: employee.office_phone,
#           streetAddress: employee.generated_address,
#           l: employee.home_city,
#           st: employee.home_state,
#           postalCode: employee.home_zip,
#           # thumbnailPhoto: Base64.decode64(employee.image_code)
#           # TODO comment back in when we bring back thumbnail photo
#         }
#       )
#     end
#   end

#   context "regular worker that has been assigned a sAMAccountName" do
#     let(:employee) { FactoryGirl.create(:employee,
#                      first_name: "Mary",
#                      last_name: "Sue",
#                      sam_account_name: "msue") }
#     let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
#                      employee: employee,
#                      manager_id: manager.employee_id) }

#     it "should generate an email using the sAMAccountName" do
#       expect(employee.generated_email).to eq("msue@opentable.com")
#     end

#     it "should create attr hash" do
#       expect(employee.ad_attrs).to eq(
#         {
#           cn: "Mary Sue",
#           dn: "cn=Mary Sue,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
#           objectclass: ["top", "person", "organizationalPerson", "user"],
#           givenName: "Mary",
#           sn: "Sue",
#           sAMAccountName: "msue",
#           displayName: employee.cn,
#           userPrincipalName: employee.generated_upn,
#           manager: manager.dn,
#           mail: "msue@opentable.com",
#           unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
#           co: employee.location.country,
#           accountExpires: employee.generated_account_expires,
#           title: employee.job_title.name,
#           description: employee.job_title.name,
#           employeeType: employee.worker_type.name,
#           physicalDeliveryOfficeName: employee.location.name,
#           department: employee.department.name,
#           employeeID: employee.employee_id,
#           telephoneNumber: employee.office_phone,
#           streetAddress: employee.generated_address,
#           l: employee.home_city,
#           st: employee.home_state,
#           postalCode: employee.home_zip,
#           # thumbnailPhoto: Base64.decode64(employee.image_code)
#           # TODO comment back in when we bring back thumbnail photo
#         }
#       )
#     end
#   end

#   context "with a contingent worker" do
#     let(:employee) { FactoryGirl.create(:employee,
#                      first_name: "Sally",
#                      last_name: "Field",
#                      sam_account_name: "sfield",
#                      contract_end_date: 1.month.from_now) }

#     let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
#                      employee: employee,
#                      manager_id: manager.employee_id) }

#     it "should set the correct account expiry" do
#       date = employee.contract_end_date + 1.day
#       time_conversion = ActiveSupport::TimeZone.new("Europe/London").local_to_utc(date)
#       expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(time_conversion))
#     end

#     it "should set the correct address" do
#       expect(employee.generated_address).to be_nil
#     end

#     it "should create attr hash" do
#       expect(employee.ad_attrs).to eq(
#         {
#           cn: "Sally Field",
#           dn: "cn=Sally Field,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
#           objectclass: ["top", "person", "organizationalPerson", "user"],
#           givenName: "Sally",
#           sn: "Field",
#           sAMAccountName: employee.sam_account_name,
#           displayName: employee.cn,
#           userPrincipalName: employee.generated_upn,
#           manager: manager.dn,
#           mail: employee.email,
#           unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
#           co: employee.location.country,
#           accountExpires: employee.generated_account_expires,
#           title: employee.job_title.name,
#           description: employee.job_title.name,
#           employeeType: employee.worker_type.name,
#           physicalDeliveryOfficeName: employee.location.name,
#           department: employee.department.name,
#           employeeID: employee.employee_id,
#           telephoneNumber: employee.office_phone,
#           streetAddress: employee.generated_address,
#           l: employee.home_city,
#           st: employee.home_state,
#           postalCode: employee.home_zip,
#           # thumbnailPhoto: Base64.decode64(employee.image_code)
#           # TODO comment back in when we bring back thumbnail photo
#         }
#       )
#     end
#   end

#   context "with a contingent worker that has been terminated" do
#     let(:cont_wt)  { FactoryGirl.create(:worker_type, :contractor) }
#     let(:employee) { FactoryGirl.create(:employee,
#                      first_name: "Bob",
#                      last_name: "Barker",
#                      contract_end_date: 1.month.from_now,
#                      termination_date: 1.day.from_now) }

#     let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
#                      worker_type: cont_wt,
#                      employee: employee,
#                      manager_id: manager.employee_id)}

#     it "should set the correct account expiry" do
#       date = employee.termination_date + 1.day
#       time_conversion = ActiveSupport::TimeZone.new("Europe/London").local_to_utc(date)
#       expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(time_conversion))
#     end

#     it "should create attr hash" do
#       expect(employee.ad_attrs).to eq(
#         {
#           cn: "Bob Barker",
#           dn: "cn=Bob Barker,ou=Operations,ou=EU,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
#           objectclass: ["top", "person", "organizationalPerson", "user"],
#           givenName: "Bob",
#           sn: "Barker",
#           sAMAccountName: employee.sam_account_name,
#           displayName: employee.cn,
#           userPrincipalName: employee.generated_upn,
#           manager: manager.dn,
#           mail: employee.email,
#           unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
#           co: employee.location.country,
#           accountExpires: employee.generated_account_expires,
#           title: employee.job_title.name,
#           description: employee.job_title.name,
#           employeeType: employee.worker_type.name,
#           physicalDeliveryOfficeName: employee.location.name,
#           department: employee.department.name,
#           employeeID: employee.employee_id,
#           telephoneNumber: employee.office_phone,
#           streetAddress: employee.generated_address,
#           l: employee.home_city,
#           st: employee.home_state,
#           postalCode: employee.home_zip,
#           # thumbnailPhoto: Base64.decode64(employee.image_code)
#           # TODO comment back in when we bring back thumbnail photo
#         }
#       )
#     end
#   end


#   context "with a remote worker and one address line" do
#     let(:employee) { FactoryGirl.create(:employee,
#                      first_name: "Bob",
#                      last_name: "Barker",
#                      home_address_1: "123 Fake St.",
#                      home_city: "Beverly Hills",
#                      home_state: "CA",
#                      home_zip: "90210") }
#     let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou, :remote,
#                      employee: employee,
#                      manager_id: manager.employee_id) }

#     it "should set the correct address" do
#       expect(employee.generated_address).to eq("123 Fake St.")
#     end

#     it "should create attr hash" do
#       expect(employee.ad_attrs).to eq(
#         {
#           cn: "Bob Barker",
#           dn: "cn=Bob Barker,ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
#           objectclass: ["top", "person", "organizationalPerson", "user"],
#           givenName: "Bob",
#           sn: "Barker",
#           sAMAccountName: employee.sam_account_name,
#           displayName: employee.cn,
#           userPrincipalName: employee.generated_upn,
#           manager: manager.dn,
#           mail: employee.email,
#           unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
#           co: employee.location.country,
#           accountExpires: employee.generated_account_expires,
#           title: employee.job_title.name,
#           description: employee.job_title.name,
#           employeeType: employee.worker_type.name,
#           physicalDeliveryOfficeName: employee.location.name,
#           department: employee.department.name,
#           employeeID: employee.employee_id,
#           telephoneNumber: employee.office_phone,
#           streetAddress: "123 Fake St.",
#           l: "Beverly Hills",
#           st: "CA",
#           postalCode: "90210",
#           # thumbnailPhoto: Base64.decode64(employee.image_code)
#           # TODO comment back in when we bring back thumbnail photo
#         }
#       )
#     end
#   end


#   context "with a remote worker and two address lines" do
#     let(:remote_loc) { FactoryGirl.create(:location, :remote) }
#     let(:employee)   { FactoryGirl.create(:employee,
#                        first_name: "Bob",
#                        last_name: "Barker",
#                        home_address_1: "123 Fake St.",
#                        home_address_2: "Apt 3G",
#                        home_city: "Beverly Hills",
#                        home_state: "CA",
#                        home_zip: "90210") }
#     let!(:profile)   { FactoryGirl.create(:profile,
#                        employee: employee,
#                        location: remote_loc,
#                        department: Department.find_by_name("Customer Support"),
#                        manager_id: manager.employee_id) }

#     it "should set the correct address" do
#       expect(employee.generated_address).to eq("123 Fake St., Apt 3G")
#     end

#     it "should create attr hash" do
#       expect(employee.ad_attrs).to eq(
#         {
#           cn: "Bob Barker",
#           dn: "cn=Bob Barker,ou=Customer Support,ou=Users,ou=OT,dc=ottest,dc=opentable,dc=com",
#           objectclass: ["top", "person", "organizationalPerson", "user"],
#           givenName: "Bob",
#           sn: "Barker",
#           sAMAccountName: employee.sam_account_name,
#           displayName: employee.cn,
#           userPrincipalName: employee.generated_upn,
#           manager: manager.dn,
#           mail: employee.email,
#           unicodePwd: "\"JoeSevenPack#007#\"".encode(Encoding::UTF_16LE).force_encoding(Encoding::ASCII_8BIT),
#           co: employee.location.country,
#           accountExpires: employee.generated_account_expires,
#           title: employee.job_title.name,
#           description: employee.job_title.name,
#           employeeType: employee.worker_type.name,
#           physicalDeliveryOfficeName: employee.location.name,
#           department: employee.department.name,
#           employeeID: employee.employee_id,
#           telephoneNumber: employee.office_phone,
#           streetAddress: "123 Fake St., Apt 3G",
#           l: "Beverly Hills",
#           st: "CA",
#           postalCode: "90210",
#           # thumbnailPhoto: Base64.decode64(employee.image_code)
#           # TODO comment back in when we bring back thumbnail photo
#         }
#       )
#     end
#   end

#   context "with a terminated worker" do
#     let(:employee) { FactoryGirl.create(:employee,
#                      termination_date: 2.days.from_now) }
#     let!(:profile) { FactoryGirl.create(:profile, :with_valid_ou,
#                     employee: employee)}

#     it "should set the correct account expiry" do
#       date = employee.termination_date + 1.day
#       time_conversion = ActiveSupport::TimeZone.new("Europe/London").local_to_utc(date)
#       expect(employee.generated_account_expires).to eq(DateTimeHelper::FileTime.wtime(time_conversion))
#     end
#   end

#   context "when it does not find a location and department ou match" do
#     let!(:employee) { FactoryGirl.create(:regular_employee) }

#     it "should assign the user to the provisional ou" do
#       expect(employee.ou).to eq("ou=Provisional,ou=Users,")
#     end
#   end
# end
