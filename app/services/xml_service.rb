class XmlService
  attr_accessor :doc

  def initialize(file)
    @doc = Nokogiri::XML(file)
  end

  def parse_to_db
    @doc.xpath("//ws:Worker").each do |w|
      attrs = {
        :first_name => w.xpath("ws:Personal//ws:Name_Data//ws:First_Name").try(:text),
        :last_name => w.xpath("ws:Personal//ws:Name_Data//ws:Last_Name").try(:text),
        :workday_username => w.xpath("ws:Additional_Information//ws:Username").try(:text),
        :employee_id => w.xpath("ws:Summary//ws:Employee_ID").try(:text),
        :country => w.xpath("ws:Position//ws:Business_Site_Country").try(:text),
        :hire_date => w.xpath("ws:Status//ws:Hire_Date").try(:text),
        :contract_end_date => s_to_DateTime(w.xpath("ws:Additional_Information//ws:Contract_End_Date").try(:text)),
        :termination_date => s_to_DateTime(w.xpath("ws:Status//ws:Termination_Date").try(:text)),
        :job_family_id => w.xpath("ws:Additional_Information//ws:OT_Job_Family_ID").try(:text),
        :job_family => w.xpath("ws:Additional_Information//ws:OT_Job_Family").try(:text),
        :job_profile_id => w.xpath("ws:Additional_Information//ws:OT_Job_Profile_ID").try(:text),
        :job_profile => w.xpath("ws:Additional_Information//ws:OT_Job_Profile").try(:text),
        :business_title => w.xpath("ws:Position//ws:Position_Title").try(:text),
        :employee_type => w.xpath("ws:Position//ws:Worker_Type").try(:text),
        :contingent_worker_type => w.xpath("ws:Additional_Information//ws:Contingent_Worker_Type").try(:text),
        :location_type => w.xpath("ws:Position//ws:Business_Site").try(:text),
        :location => w.xpath("ws:Position//ws:Business_Site_Name").try(:text),
        :manager_id => w.xpath("ws:Position//ws:Supervisor_ID").try(:text),
        :cost_center_id => w.xpath("ws:Additional_Information//ws:Cost_Center_Code").try(:text),
        :office_phone => w.xpath("ws:Additional_Information//ws:Primary_Work_Phone").try(:text),
        :image_code => w.xpath("ws:Photo//ws:Image").try(:text),
        :home_address_1 => nil,
        :home_address_2 => nil,
        :home_city => nil,
        :home_state => nil,
        :home_zip => nil,
        :leave_start_date => nil,
        :leave_return_date => nil
      }

      attrs[:cost_center] = COST_CENTERS[attrs[:cost_center_id][-6,6]] if attrs[:cost_center_id].present?

      w.xpath("ws:Leave_of_Absence").each do |l|
        if attrs[:leave_start_date] == nil || (attrs[:leave_start_date].present? && attrs[:leave_start_date] < s_to_DateTime(l.xpath("ws:Leave_Start_Date").text))
          attrs[:leave_start_date] = s_to_DateTime(l.xpath("ws:Leave_Start_Date").try(:text))
          attrs[:leave_return_date] = s_to_DateTime(l.xpath("ws:First_Day_of_Work").try(:text))
        end
      end

      if w.xpath("ws:Position//ws:Business_Site").first.text == "Remote Location"
        w.xpath("ws:Personal//ws:Address_Data").each do |a|
          if a.xpath("ws:Address_Type").first.text == "HOME"
            attrs[:home_address_1] = a.xpath("*[@ws:Label='Address Line 1']").try(:text)
            attrs[:home_address_2] = a.xpath("*[@ws:Label='Address Line 2']").try(:text)
            attrs[:home_city] = a.xpath("ws:Municipality").try(:text)
            attrs[:home_state] = a.xpath("ws:Region").try(:text)
            attrs[:home_zip] = a.xpath("ws:Postal_Code").try(:text)
          end
        end
      end

      e = Employee.where(:employee_id => attrs[:employee_id]).try(:first)
      e.present? ? Employee.update(e.id, attrs) : Employee.create(attrs)
    end
  end

  def s_to_DateTime(date_string)
    date_string.present? ? DateTime.iso8601(date_string) : nil
  end
end
