# Concur List Import
# http://www.concurtraining.com/customers/tech_pubs/Docs/_Current/SPC/Spc_Shr/Shr_SPEC_List_Imp.pdf
module ConcurImporter
  class List

    def locations
      locations = Location.where(status: 'Active').order(:name).all
      create_csv('Locations', locations)
    end

    def departments
      departments = Department.where(status: 'Active').order(:name).all
      create_csv('Departments', departments)
    end

    private

    def file_name(list)
      "tmp/concur/list_#{SECRETS.concur_entity_code}_#{list}_#{Time.now.strftime('%Y%m%d%H%M%S')}.txt"
    end

    def create_csv(list_name, collection)
      csv_file_name = file_name(list_name.downcase)

      CSV.open(csv_file_name, 'w+:bom|utf-8') do |csv|
        collection.each do |item|
          level_1_code = item.code
          value = item.name

          # Fields marked by * are required
          csv << [
            list_name,      # 01: * List Name: Must have been created in admin tool
            'ConcurLists',  # 02: * List Category Name:
            level_1_code,   # 03: * Level 1 Code
            nil,            # 04:   Level 2 Code
            nil,            # 05:   Level 3 Code
            nil,            # 06:   Level 4 Code
            nil,            # 07:   Level 5 Code
            nil,            # 08:   Level 6 Code
            nil,            # 09:   Level 7 Code
            nil,            # 10:   Level 8 Code
            nil,            # 11:   Level 9 Code
            nil,            # 12:   Level 10 Code
            value,          # 13: * Value, or item name for loest level code
            '20180101',     # 14:   Start Date: YYYYMMDD
            nil,            # 15:   End Date: YYYYMMDD
            'N'             # 16:   Delete List Item, Y or N, default N
          ]
        end
      end
    end
  end
end
