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
    let(:filename)    { "/tmp/concur/employee_#{SECRETS.concur_entity_code}_#{Time.now.strftime('%Y%m%d%H%M%S')}.txt" }
    let(:filepath)    { Rails.root.to_s + filename }
    let(:service)     { ConcurImporter::EnhancedEmployee.new }
    let(:currency)    { FactoryGirl.create(:currency, iso_alpha_code: 'USD') }
    let(:country)     { FactoryGirl.create(:country, :us, currency: currency) }
    let(:address)     { FactoryGirl.create(:address, country: country) }
    let(:location)    { FactoryGirl.create(:location, code: 'XX', address: address) }
    let(:biz_unit)    { FactoryGirl.create(:business_unit, name: 'biz unit x') }
    let(:department)  { FactoryGirl.create(:department, code: 'deptxx', name: 'dname') }
    let(:worker_type) do
      FactoryGirl.create(:worker_type,
        kind: 'Regular',
        code: 'FTR',
        name: 'Regular Full-Time')
    end
    let(:manager) do
      FactoryGirl.create(:employee,
        legal_first_name: 'Brandon',
        first_name: 'Bran',
        last_name: 'Smith',
        email: 'email1@example.com',
        status: 'active')
    end
    let!(:manager_p) do
      FactoryGirl.create(:profile,
        employee: manager,
        adp_employee_id: '111',
        profile_status: 'active',
        location: location,
        department: department,
        worker_type: worker_type,
        business_unit: biz_unit)
    end
    let(:worker) do
      FactoryGirl.create(:employee,
        legal_first_name: 'John',
        first_name: 'John',
        last_name: 'Keynes',
        status: 'active',
        email: 'email2@example.com',
        manager: manager,
        payroll_file_number: '222')
    end
    let!(:profile) do
      FactoryGirl.create(:profile,
        employee: worker,
        adp_employee_id: '222',
        profile_status: 'active',
        location: location,
        department: department,
        worker_type: worker_type,
        business_unit: biz_unit)
    end
    let(:csv) do
      <<-EOS.strip_heredoc
      100,0,WELCOME,UPDATE,EN,N,N
      305,John,,Keynes,222,email2@example.com,,email2@example.com,en_US,US,,DEFAULT,USD,,Y,,,,,,,biz unit x,,,,,,,,,deptxx,XX,0,222,,,,,,,,US,,,,,,,,,,,,,,,,,111,,,,,N,,,,,,,,,,,,,111,,,,,,,,,Y,US,,,ADPPAYR,222,WP8,E,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
      305,Brandon,,Smith,111,email1@example.com,,email1@example.com,en_US,US,,DEFAULT,USD,,Y,,,,,,,biz unit x,,,,,,,,,deptxx,XX,0,111,,,,,,,,US,,,,,,,,,,,,,,,,,,,,,,Y,,,,,,,,,,,,,,,,,,,,,,Y,US,,,ADPPAYR,111,WP8,E,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
      EOS
    end

    it 'has the right content' do
      service.generate_csv([worker, manager])
      expect(File.read(filepath)).to eq(csv)
    end
  end
end
