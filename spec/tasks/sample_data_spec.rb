require 'rails_helper'
require 'rake'

describe "db:sample_data", type: :tasks do
  before :all do
    Department.create(:name => "Sample", :code => "12345")
    Location.create(:name => "OT San Francisco", :kind => "Office", :country => "US")
    Rake.application = Rake::Application.new
    Rake.application.rake_require "lib/tasks/sample_data", [Rails.root.to_s], ''
    Rake::Task.define_task :environment
  end

  context "db:sample_data:load" do
    it "should load correct sample data" do
      Rake::Task["db:sample_data:load"].invoke
      expect(Employee.count).to eq(2)
    end
  end

  context "db:sample_data:lebowski" do
    it "should load lebowski" do
      Rake::Task["db:sample_data:lebowski"].invoke
      expect(Employee.count).to eq(1)
      expect(Employee.first.last_name).to eq("Lebowski")
      expect(Employee.first.profiles.active.job_title.name).to eq("Test")
      expect(Employee.first.job_title.name).to eq("Test")
    end
  end
end
