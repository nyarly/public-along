class XmlService
  attr_accessor :file, :doc, :new_hires, :existing_employees

  def initialize(file=latest_xml_file)
    @file = file
    @doc = doc
    @new_hires = []
    @existing_employees = []
  end

  def doc
    @file.present? ? Nokogiri::XML(@file) : nil
  end

  def latest_xml_file
    # Find all .xml files in lib/assets/ and use the file with the most recent date stamp
    file = nil
    filepath = nil
    hash = Hash.new { |k,v| k[v] = [] }
    Dir["lib/assets/*.xml"].each do |f|
      hash[f] = f.gsub(/\D/,"").to_i
    end
    hash.each { |k,v| filepath = k if v == hash.values.max }
    if XmlTransaction.where(:checksum => checksum(filepath)).empty?
      file = File.new(filepath)
    end
  end

  def parse_to_db
    @doc.xpath("//ws:Worker").each do |w|
      attrs = base_attrs(w).merge(leave_attrs(w)).merge(address_attrs(w))

      attrs[:cost_center] = COST_CENTERS[attrs[:cost_center_id][-6,6]] if attrs[:cost_center_id].present?
      sort_employee(attrs)
    end
  end

  def parse_to_ad
    parse_to_db

    ads = ActiveDirectoryService.new
    ads.create_disabled_accounts(new_hires)
    HttpService.post_emails(SECRETS.xml_post_url, emails_xml)
    ads.update(existing_employees)
    trans = XmlTransaction.create(
      :name => File.basename(file),
      :checksum => checksum(file)
    )
  end

  def emails_xml
    builder = Nokogiri::XML::Builder.new do |xml|
      xml.root {
        @new_hires.each do |worker|
          if worker.email
            xml.individual {
              xml.identifier worker.employee_id
              xml.email worker.email
            }
          end
        end
      }
    end
    builder.to_xml
  end

  def get_text(node, path)
    text = node.xpath(path).try(:text)
    text.blank? ? nil : text
  end

  def base_attrs(worker_node)
    {
      :first_name => get_text(worker_node, "ws:Personal//ws:Name_Data//ws:First_Name"),
      :last_name => get_text(worker_node, "ws:Personal//ws:Name_Data//ws:Last_Name"),
      :workday_username => get_text(worker_node, "ws:Additional_Information//ws:Username"),
      :employee_id => get_text(worker_node, "ws:Summary//ws:Employee_ID"),
      :country => get_text(worker_node, "ws:Position//ws:Business_Site_Country"),
      :hire_date => get_text(worker_node, "ws:Status//ws:Hire_Date"),
      :contract_end_date => s_to_DateTime(get_text(worker_node, "ws:Additional_Information//ws:Contract_End_Date")),
      :termination_date => s_to_DateTime(get_text(worker_node, "ws:Status//ws:Termination_Date")),
      :job_family_id => get_text(worker_node, "ws:Additional_Information//ws:OT_Job_Family_ID"),
      :job_family => get_text(worker_node, "ws:Additional_Information//ws:OT_Job_Family"),
      :job_profile_id => get_text(worker_node, "ws:Additional_Information//ws:OT_Job_Profile_ID"),
      :job_profile => get_text(worker_node, "ws:Additional_Information//ws:OT_Job_Profile"),
      :business_title => get_text(worker_node, "ws:Position//ws:Position_Title"),
      :employee_type => get_text(worker_node, "ws:Position//ws:Worker_Type"),
      :contingent_worker_type => get_text(worker_node, "ws:Additional_Information//ws:Contingent_Worker_Type"),
      :location_type => get_text(worker_node, "ws:Position//ws:Business_Site"),
      :location => get_text(worker_node, "ws:Position//ws:Business_Site_Name"),
      :manager_id => get_text(worker_node, "ws:Position//ws:Supervisor_ID"),
      :cost_center_id => get_text(worker_node, "ws:Additional_Information//ws:Cost_Center_Code"),
      :office_phone => get_text(worker_node, "ws:Additional_Information//ws:Primary_Work_Phone"),
      :image_code => get_text(worker_node, "ws:Photo//ws:Image")
    }
  end

  def leave_attrs(worker_node)
    attrs = {}
    worker_node.xpath("ws:Leave_of_Absence").each do |l|
      if attrs[:leave_start_date] == nil || (attrs[:leave_start_date].present? && attrs[:leave_start_date] < s_to_DateTime(get_text(l, "ws:Leave_Start_Date")))
        attrs[:leave_start_date] = s_to_DateTime(get_text(l, "ws:Leave_Start_Date"))
        attrs[:leave_return_date] = s_to_DateTime(get_text(l, "ws:First_Day_of_Work"))
      end
    end
    attrs
  end

  def address_attrs(worker_node)
    # Only save home address if the worker is remote
    attrs = {}
    if worker_node.xpath("ws:Position//ws:Business_Site").first.text == "Remote Location"
      worker_node.xpath("ws:Personal//ws:Address_Data").each do |a|
        if a.xpath("ws:Address_Type").first.text == "HOME"
          attrs[:home_address_1] = get_text(a, "*[@ws:Label='Address Line 1']")
          attrs[:home_address_2] = get_text(a, "*[@ws:Label='Address Line 2']")
          attrs[:home_city] = get_text(a, "ws:Municipality")
          attrs[:home_state] = get_text(a, "ws:Region")
          attrs[:home_zip] = get_text(a, "ws:Postal_Code")
        end
      end
    end
    attrs
  end

  def sort_employee(attrs)
    e = Employee.where(:employee_id => attrs[:employee_id]).try(:first)

    if e.present?
      existing = Employee.update(e.id, attrs)
      if existing.valid?
        @existing_employees << existing
      else
        TechTableMailer.alert_email("ERROR: Update of #{existing.first_name} #{existing.last_name} in workday-integration DB failed. Manual update required. Attributes: #{attrs}").deliver_now
      end
    else
      new_emp = Employee.create(attrs)
      if new_emp.valid?
        @new_hires << new_emp
      else
        TechTableMailer.alert_email("ERROR: Creation of #{new_emp.first_name} #{new_emp.last_name} in workday-integration DB failed. Manual create required. Attributes: #{attrs}").deliver_now
      end
    end
  end

  def checksum(file_or_path)
    Digest::MD5.hexdigest(File.read(file_or_path))
  end

  def s_to_DateTime(date_string)
    date_string.present? ? DateTime.iso8601(date_string) : nil
  end
end
