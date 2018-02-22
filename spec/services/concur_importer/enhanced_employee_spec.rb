require 'rails_helper'

describe ConcurImporter::EnhancedEmployee, type: :service do
  before do
    Dir['tmp/concur/*'].each do |f|
      File.delete(f)
    end

    dirname = 'tmp/concur'
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
  end

  after do
    Dir['tmp/concur/*'].each do |f|
      File.delete(f)
    end
  end

  describe '#generate_csv' do
    let(:filename)  { "/tmp/concur/employee_#{SECRETS.concur_entity_code}_#{DateTime.now.strftime('%Y%m%d%H%M%S')}.txt" }
    let(:service)   { ConcurImporter::EnhancedEmployee.new }
    let(:filepath)  { Rails.root.to_s + filename }
    let(:currency)    { FactoryGirl.create(:currency, iso_alpha_code: 'USD') }
    let(:country)     { FactoryGirl.create(:country, :us, currency: currency) }
    let(:address)     { FactoryGirl.create(:address, country: country) }
    let(:location)    { FactoryGirl.create(:location, code: 'XX', address: address) }
    let(:department)  { FactoryGirl.create(:department, code: 'deptxx', name: 'dname') }
    let(:worker_type) { FactoryGirl.create(:worker_type,
                        kind: 'Regular',
                        code: 'FTR',
                        name: 'Regular Full-Time') }
    let(:service)     { ConcurImporter::EnhancedEmployee.new }
    let(:manager)     { FactoryGirl.create(:manager,
                        first_name: 'Adam',
                        last_name: 'Smith',
                        email: 'email1@example.com',
                        status: 'active') }
    let!(:manager_p)  { FactoryGirl.create(:profile,
                        employee: manager,
                        adp_employee_id: '111',
                        profile_status: 'active',
                        location: location,
                        department: department,
                        worker_type: worker_type,
                        management_position: true) }
    let(:worker)      { FactoryGirl.create(:employee,
                        first_name: 'John',
                        last_name: 'Keynes',
                        status: 'active',
                        email: 'email2@example.com',
                        manager: manager,
                        payroll_file_number: '222') }
    let!(:profile)   { FactoryGirl.create(:profile,
                        employee: worker,
                        adp_employee_id: '222',
                        profile_status: 'active',
                        location: location,
                        department: department,
                        worker_type: worker_type,
                        management_position: false) }
    let(:csv)       {
      <<-EOS.strip_heredoc
      305,John,,Keynes,222,email2@example.com,,email2@example.com,en_US,US,,DEFAULT,USD,,Y,,,,,,,"OpenTable\, Inc\.",,,,,,,,,deptxx,XX,0,222,,,,,,,,United States,,,,,,,,,,,,,,,,,111,111,111,111,,,,,,,,,,,,,,,111,Y,N,,,,,,,Y,United States,,,ADPPAYR,222,WP8,E,,,,,,
      305,Adam,,Smith,111,email1@example.com,,email1@example.com,en_US,US,,DEFAULT,USD,,Y,,,,,,,"OpenTable\, Inc\.",,,,,,,,,deptxx,XX,0,111,,,,,,,,United States,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,Y,Y,,,,,,,Y,United States,,,ADPPAYR,111,WP8,E,,,,,,
      EOS
    }

    it 'has the right content' do
      service.generate_csv([worker, manager])
      expect(File.read(filepath)).to eq(csv)
    end
  end
end
