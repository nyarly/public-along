require 'rails_helper'

describe ConcurImporter::Upload, type: :service do
  let(:sftp) { double.as_null_object }
  let(:conn_info) { ['st.fakehost.com', 'fake', { password: 'secret_word', port: 99 }] }

  before do
    Timecop.freeze(Time.new(2018, 2, 14, 22, 0, 0, '+00:00'))

    allow(Net::SFTP).to receive(:start).with(*conn_info).and_yield(sftp)

    dirname = 'tmp/concur'
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
    Dir["#{dirname}/*"].each do |f|
      File.delete(f)
    end
  end

  after do
    Timecop.return

    Dir['tmp/concur/*'].each do |f|
      File.delete(f)
    end
  end

  describe '#encrypt_and_upload_single_file' do
    subject(:upload) { ConcurImporter::Upload.new }

    let(:filepath)  { Rails.root.to_s + '/tmp/concur/arbitrary_name.txt' }
    let(:encrypted) { Rails.root.to_s + '/tmp/concur/arbitrary_name.txt.gpg' }

    before do
      CSV.open(filepath, 'w+:bom|utf-8') do |csv|
        csv << %w[test upload]
      end

      upload.encrypt_and_upload_single_file('tmp/concur/arbitrary_name.txt')
    end

    it 'creates an encrypted file' do
      expect(File.exist?(encrypted)).to be(true)
    end

    it 'has encrypted contents' do
      expect(File.read(encrypted)).to include('BEGIN PGP MESSAGE')
    end

    it 'uploads the file' do
      expect(sftp).to have_received(:upload!)
        .with('tmp/concur/arbitrary_name.txt.gpg', '/in/arbitrary_name.txt.gpg')
    end
  end

  describe '#all' do
    let(:query)    { instance_double(ConcurUploadQuery) }
    let(:employee) { FactoryGirl.create(:active_employee, legal_first_name: 'Fname') }
    let(:loc_txt)  { Rails.root.to_s + '/tmp/concur/list_fake_location_20180214140000.txt' }
    let(:loc_gpg)  { Rails.root.to_s + '/tmp/concur/list_fake_location_20180214140000.txt.gpg' }
    let(:dept_txt) { Rails.root.to_s + '/tmp/concur/list_fake_department_20180214140000.txt' }
    let(:dept_gpg) { Rails.root.to_s + '/tmp/concur/list_fake_department_20180214140000.txt.gpg' }
    let(:emp_txt)  { Rails.root.to_s + '/tmp/concur/employee_fake_20180214140000.txt' }
    let(:emp_gpg)  { Rails.root.to_s + '/tmp/concur/employee_fake_20180214140000.txt.gpg' }

    context 'when there are employee changes' do
      subject(:upload) { ConcurImporter::Upload.new }

      before do
        allow(ConcurUploadQuery).to receive(:new).and_return(query)
        allow(query).to receive(:daily_sync_group).and_return([employee])
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

      it 'uploads encrypted employee file' do
        upload.all

        expect(sftp).to have_received(:upload!)
          .with('tmp/concur/employee_fake_20180214140000.txt.gpg', '/in/employee_fake_20180214140000.txt.gpg')
      end

      it 'uploads encrypted department file' do
        upload.all

        expect(sftp).to have_received(:upload!)
          .with('tmp/concur/list_fake_department_20180214140000.txt.gpg', '/in/list_fake_department_20180214140000.txt.gpg')
      end

      it 'uploads encrypted location file' do
        upload.all

        expect(sftp).to have_received(:upload!)
          .with('tmp/concur/list_fake_location_20180214140000.txt.gpg', '/in/list_fake_location_20180214140000.txt.gpg')
      end
    end

    context 'when there are no employee changes' do
      subject(:upload) { ConcurImporter::Upload.new }

      before do
        allow(ConcurUploadQuery).to receive(:new).and_return(query)
        allow(query).to receive(:daily_sync_group).and_return([])
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

      it 'uploads encrypted department file' do
        upload.all

        expect(sftp).to have_received(:upload!)
          .with('tmp/concur/list_fake_department_20180214140000.txt.gpg', '/in/list_fake_department_20180214140000.txt.gpg')
      end

      it 'uploads encrypted location file' do
        upload.all

        expect(sftp).to have_received(:upload!)
          .with('tmp/concur/list_fake_location_20180214140000.txt.gpg', '/in/list_fake_location_20180214140000.txt.gpg')
      end
    end
  end
end
