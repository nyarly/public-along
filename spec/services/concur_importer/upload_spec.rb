require 'rails_helper'

describe ConcurImporter::Upload, type: :service do
  before do
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
    Timecop.return
  end

  describe '#all' do
    let(:list)            { ConcurImporter::List.new }
    let(:emp_import)      { ConcurImporter::EnhancedEmployee.new }
    let(:employee)        { FactoryGirl.create(:active_employee) }
    let(:loc_filepath)    { Rails.root.to_s + '/tmp/concur/list_fake_locations_20180214160000.txt' }
    let(:dept_filepath)   { Rails.root.to_s + '/tmp/concur/list_fake_departments_20180214160000.txt' }
    let(:emp_filepath)    { Rails.root.to_s + '/tmp/concur/employees_fake_20180214160000.txt' }
    let(:loc_crypt_path)  { Rails.root.to_s + '/tmp/concur/list_fake_locations_20180214160000.txt.gpg' }
    let(:dept_crypt_path) { Rails.root.to_s + '/tmp/concur/list_fake_departments_20180214160000.txt.gpg' }
    let(:emp_crypt_path)  { Rails.root.to_s + '/tmp/concur/employees_fake_20180214160000.txt.gpg' }

    before do
      Timecop.freeze(Time.new(2018, 2, 14, 16, 0, 0, '+00:00'))
      allow(ConcurImporter::List).to receive(:new).and_return(list).twice
      allow(ConcurImporter::EnhancedEmployee).to receive(:new).and_return(emp_import)
      allow(list).to receive(:locations)
      allow(list).to receive(:departments)
      allow(emp_import).to receive(:generate_csv)
      allow(upload).to receive(:encrypt)
      allow(upload).to receive(:upload_files)
    end

    context 'when there are employee changes' do
      subject(:upload) { ConcurImporter::Upload.new }

      before do
        allow(EmployeeQuery).to receive_message_chain(:new, :concur_upload_group).and_return([employee])
        allow(upload).to receive(:all_filepaths).and_return([loc_filepath, dept_filepath, emp_filepath, loc_crypt_path, dept_crypt_path, emp_crypt_path])
      end

      it 'generates a new location list' do
        upload.all
        expect(list).to have_received(:locations)
      end

      it 'generates a new department list' do
        upload.all
        expect(list).to have_received(:departments)
      end

      it 'generates a new employee list' do
        upload.all
        expect(emp_import).to have_received(:generate_csv).with([employee])
      end

      it 'encrypts the location list' do
        upload.all
        expect(upload).to have_received(:encrypt).with(loc_filepath)
      end

      it 'encrypts the department list' do
        upload.all
        expect(upload).to have_received(:encrypt).with(dept_filepath)
      end

      it 'encrypts the employee list' do
        upload.all
        expect(upload).to have_received(:encrypt).with(emp_filepath)
      end

      it 'uploads the encrypted files' do
        upload.all
        expect(upload).to have_received(:upload_files).with([loc_crypt_path, dept_crypt_path, emp_crypt_path])
      end
    end

    context 'when there are no employee changes' do
      subject(:upload) { ConcurImporter::Upload.new }

      before do
        allow(EmployeeQuery).to receive_message_chain(:new, :concur_upload_group).and_return(nil)
        allow(upload).to receive(:all_filepaths).and_return([loc_filepath, dept_filepath, loc_crypt_path, dept_crypt_path])
      end

      it 'generates a new location list' do
        upload.all
        expect(list).to have_received(:locations)
      end

      it 'generates a new department list' do
        upload.all
        expect(list).to have_received(:departments)
      end

      it 'does not generate a new employee list' do
        upload.all
        expect(emp_import).not_to have_received(:generate_csv)
      end

      it 'encrypts the location list' do
        upload.all
        expect(upload).to have_received(:encrypt).with(loc_filepath)
      end

      it 'encrypts the department list' do
        upload.all
        expect(upload).to have_received(:encrypt).with(dept_filepath)
      end

      it 'does not have the employee list to encrypt' do
        upload.all
        expect(upload).not_to have_received(:encrypt).with(emp_filepath)
      end

      it 'uploads the encrypted files' do
        upload.all
        expect(upload).to have_received(:upload_files).with([loc_crypt_path, dept_crypt_path])
      end
    end
  end
end
