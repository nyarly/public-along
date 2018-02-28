require 'rails_helper'

describe ConcurImporter::Upload, type: :service do
  let(:sftp) { class_double(Net::SFTP) }

  before do
    allow(Net::SFTP).to receive(:start).and_return(sftp)
    dirname = 'tmp/concur'

    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

    Dir["#{dirname}/*"].each do |f|
      File.delete(f)
    end
  end

  after do
    Dir['tmp/concur/*'].each do |f|
      File.delete(f)
    end
  end

  describe '#all' do
    let(:query)    { double(EmployeeQuery) }
    let(:employee) { FactoryGirl.create(:active_employee) }
    let(:loc_txt)  { Rails.root.to_s + '/tmp/concur/list_fake_location_20180214140000.txt' }
    let(:loc_gpg)  { Rails.root.to_s + '/tmp/concur/list_fake_location_20180214140000.txt.gpg' }
    let(:dept_txt) { Rails.root.to_s + '/tmp/concur/list_fake_department_20180214140000.txt' }
    let(:dept_gpg) { Rails.root.to_s + '/tmp/concur/list_fake_department_20180214140000.txt.gpg' }
    let(:emp_txt)  { Rails.root.to_s + '/tmp/concur/employee_fake_20180214140000.txt' }
    let(:emp_gpg)  { Rails.root.to_s + '/tmp/concur/employee_fake_20180214140000.txt.gpg' }

    context 'when there are employee changes' do
      subject(:upload) { ConcurImporter::Upload.new }

      before do
        Timecop.freeze(Time.new(2018, 2, 14, 22, 0, 0, '+00:00'))
        allow(EmployeeQuery).to receive(:new).and_return(query)
        allow(query).to receive(:concur_upload_group).and_return([employee])
      end

      after do
        Timecop.return
      end

      it 'creates a location txt file' do
        upload.all
        expect(File.exist?(loc_txt)).to be(true)
      end

      it 'creates a department txt file' do
        upload.all
        expect(File.exist?(dept_txt)).to be(true)
      end

      it 'creates an employee txt file' do
        upload.all
        expect(File.exist?(emp_txt)).to be(true)
      end

      it 'encrypts the location file' do
        upload.all
        expect(File.read(loc_gpg)).to include('BEGIN PGP MESSAGE')
      end

      it 'encrypts the department file' do
        upload.all
        expect(File.read(dept_gpg)).to include('BEGIN PGP MESSAGE')
      end

      it 'encrypts the employee file' do
        upload.all
        expect(File.read(emp_gpg)).to include('BEGIN PGP MESSAGE')
      end
    end

    context 'when there are no employee changes' do
      subject(:upload) { ConcurImporter::Upload.new }

      before do
        Timecop.freeze(Time.new(2018, 2, 14, 22, 0, 0, '+00:00'))
        allow(EmployeeQuery).to receive(:new).and_return(query)
        allow(query).to receive(:concur_upload_group).and_return([])
      end

      after do
        Timecop.return
      end

      it 'creates a location txt file' do
        upload.all
        expect(File.exist?(loc_txt)).to be(true)
      end

      it 'creates a department txt file' do
        upload.all
        expect(File.exist?(dept_txt)).to be(true)
      end

      it 'does not create an employee txt file' do
        upload.all
        expect(File.exist?(emp_txt)).to be(false)
      end

      it 'encrypts the location file' do
        upload.all
        expect(File.read(loc_gpg)).to include('BEGIN PGP MESSAGE')
      end

      it 'encrypts the department file' do
        upload.all
        expect(File.read(dept_gpg)).to include('BEGIN PGP MESSAGE')
      end

      it 'does not have an encrypted employee file' do
        upload.all
        expect(File.exist?(emp_gpg)).to be(false)
      end
    end
  end
end
