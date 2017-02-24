namespace :db do
  namespace :saba do
    desc "load orgs"
    task :load_orgs => :environment do
      orgs = [
        {name:"Executive & Facilities", code: "ADMN"},
          {name:"Business Development & Partnerships", code: "BSDV"},
          {name:"Technology", code: "ENGI"},
          {name:"Global Finance", code: "FNTA"},
          {name:"People & Culture", code: "HRRF"},
          {name:"Legal & Risk Mgt", code: "LGLR"},
          {name:"Marketing", code: "MKTG"},
          {name:"Product Management", code: "PDMT"},
          {name:"Global Sales & Services", code: "SALE"}
      ]
      orgs.each do |attrs|
        po = ParentOrg.find_or_create_by(code: attrs[:code])
        po.update_attributes(attrs)
      end

      depts = [{:name=>"Facilities", :code=>"010000", :parent_org_id=>ParentOrg.find_by(code: "ADMN").id},
               {:name=>"People & Culture-HR & Total Rewards", :code=>"011000", :parent_org_id=>ParentOrg.find_by(code: "HRRF").id},
               {:name=>"Internal Audit", :code=>"009000", :parent_org_id=>ParentOrg.find_by(code: "ADMN").id},
               {:name=>"Legal", :code=>"012000", :parent_org_id=>ParentOrg.find_by(code: "LGLR").id},
               {:name=>"Finance", :code=>"013000", :parent_org_id=>ParentOrg.find_by(code: "FNTA").id},
               {:name=>"Risk Management", :code=>"014000", :parent_org_id=>ParentOrg.find_by(code: "LGLR").id},
               {:name=>"People & Culture-Talent Acquisition", :code=>"017000", :parent_org_id=>ParentOrg.find_by(code: "HRRF").id},
               {:name=>"Executive", :code=>"018000", :parent_org_id=>ParentOrg.find_by(code: "ADMN").id},
               {:name=>"Finance Operations", :code=>"019000", :parent_org_id=>ParentOrg.find_by(code: "FNTA").id},
               {:name=>"Sales", :code=>"020000", :parent_org_id=>ParentOrg.find_by(code: "SALE").id},
               {:name=>"Sales Operations", :code=>"021000", :parent_org_id=>ParentOrg.find_by(code: "SALE").id},
               {:name=>"Inside Sales", :code=>"025000", :parent_org_id=>ParentOrg.find_by(code: "SALE").id},
               {:name=>"Field Operations", :code=>"031000", :parent_org_id=>ParentOrg.find_by(code: "SALE").id},
               {:name=>"Customer Support", :code=>"032000", :parent_org_id=>ParentOrg.find_by(code: "SALE").id},
               {:name=>"Customer Support - Contact Center", :code=>"037000", :parent_org_id=>ParentOrg.find_by(code: "SALE").id},
               {:name=>"Restaurant Relations Management", :code=>"033000", :parent_org_id=>ParentOrg.find_by(code: "ENGI").id},
               {:name=>"Tech Table", :code=>"035000", :parent_org_id=>ParentOrg.find_by(code: "ENGI").id},
               {:name=>"Infrastructure Engineering", :code=>"036000", :parent_org_id=>ParentOrg.find_by(code: "ENGI").id},
               {:name=>"Technology/CTO Admin", :code=>"040000", :parent_org_id=>ParentOrg.find_by(code: "ENGI").id},
               {:name=>"Product Engineering - Front End Diner", :code=>"041000", :parent_org_id=>ParentOrg.find_by(code: "ENGI").id},
               {:name=>"Product Engineering - Front End Restaurant", :code=>"042000", :parent_org_id=>ParentOrg.find_by(code: "ENGI").id},
               {:name=>"Product Engineering - Back End", :code=>"043000", :parent_org_id=>ParentOrg.find_by(code: "ENGI").id},
               {:name=>"BizOpti/Internal Systems Engineering", :code=>"044000", :parent_org_id=>ParentOrg.find_by(code: "ENGI").id},
               {:name=>"Data Analytics & Experimentation", :code=>"045000", :parent_org_id=>ParentOrg.find_by(code: "ENGI").id},
               {:name=>"Data Science", :code=>"046000", :parent_org_id=>ParentOrg.find_by(code: "ENGI").id},
               {:name=>"Brand/General Marketing", :code=>"050000", :parent_org_id=>ParentOrg.find_by(code: "MKTG").id},
               {:name=>"Consumer Marketing", :code=>"051000", :parent_org_id=>ParentOrg.find_by(code: "MKTG").id},
               {:name=>"Restaurant Marketing", :code=>"052000", :parent_org_id=>ParentOrg.find_by(code: "MKTG").id},
               {:name=>"Public Relations", :code=>"053000", :parent_org_id=>ParentOrg.find_by(code: "MKTG").id},
               {:name=>"Product Marketing", :code=>"054000", :parent_org_id=>ParentOrg.find_by(code: "PDMT").id},
               {:name=>"Restaurant Product Management", :code=>"061000", :parent_org_id=>ParentOrg.find_by(code: "PDMT").id},
               {:name=>"Consumer Product Management", :code=>"062000", :parent_org_id=>ParentOrg.find_by(code: "PDMT").id},
               {:name=>"Design", :code=>"063000", :parent_org_id=>ParentOrg.find_by(code: "MKTG").id},
               {:name=>"Business Development", :code=>"070000", :parent_org_id=>ParentOrg.find_by(code: "BSDV").id}]

      ActiveRecord::Base.transaction do
        depts.each { |attrs|
          dept = Department.find_or_create_by(code: attrs[:code])
          dept.update_attributes(attrs)
        }
      end
    end

    desc "update csvs"
    task :update_csvs => :environment do
      ss = SabaService.new
      ss.generate_csvs
    end

    desc "drop to SABA via sFTP"
    task :sftp_drop => :environment do
      ss = SabaService.new
      ss.sftp_drop
    end
  end
end


# ActiveRecord::Base.transaction do
#   depts.each { |attrs|
#     dept = Department.find_or_create_by(name: attrs[:name])
#     dept.update_attributes(attrs)
#   }
#   locs.each { |attrs|
#     loc = Location.find_or_create_by(name: attrs[:name])
#     loc.update_attributes(attrs)
#   }
#   mach_bundles.each { |attrs|
#     mb = MachineBundle.find_or_create_by(name: attrs[:name])
#     mb.update_attributes(attrs)
#   }
# end
