require 'rails_helper'

describe ConcurImporter::IdInformation, type: :service do
  let(:csv) do
    [['Lname1, Fname1', 'oldid1', '1@example.com'],
     ['Lname2, Fname2', 'oldid2', '2@example.com']]
  end

  before do
    FactoryGirl.create(:profile,
      adp_employee_id: '112233',
      profile_status: 'active',
      employee_args: {
        status: 'active',
        email: '1@example.com',
        first_name: 'Fname1',
        last_name: 'Lname1'
      })

    dirname = 'tmp/concur'
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

    Dir['tmp/concur/*'].each do |f|
      File.delete(f)
    end

    allow(CSV).to receive(:read).and_return(csv)
  end

  after do
    Dir['tmp/concur/*'].each do |f|
      File.delete(f)
    end
  end

  describe '#sort_entries' do
    subject(:id_info) { ConcurImporter::IdInformation.new }

    context 'when all workers found' do
      before do
        FactoryGirl.create(:profile,
          adp_employee_id: '332211',
          profile_status: 'active',
          employee_args: {
            status: 'active',
            email: '2@example.com',
            first_name: 'Fname2',
            last_name: 'Lname2'
          })
      end

      it 'identifies valid entries' do
        expect(id_info.sort_entries('fakepath')[0]).to eq([%w[oldid1 112233], %w[oldid2 332211]])
      end

      it 'does not find any invalid entries' do
        expect(id_info.sort_entries('fakepath')[1]).to eq([])
      end
    end

    context 'when worker is not found' do
      before do
        FactoryGirl.create(:profile,
          adp_employee_id: '332211',
          profile_status: 'active',
          employee_args: {
            status: 'active',
            email: 'xxx@example.com',
            first_name: 'Fname2',
            last_name: 'Lname2'
          })
      end

      it 'identifies valid entries' do
        expect(id_info.sort_entries('fakepath')[0]).to eq([%w[oldid1 112233]])
      end

      it 'identifies invalid entries' do
        expect(id_info.sort_entries('fakepath')[1])
          .to eq([['Lname2, Fname2', 'oldid2', '2@example.com']])
      end
    end

    context 'when worker name is mismatched' do
      before do
        FactoryGirl.create(:profile,
          adp_employee_id: '332211',
          profile_status: 'active',
          employee_args: {
            status: 'active',
            email: '2@example.com',
            first_name: 'Fnamex',
            last_name: 'Lnamex'
          })
      end

      it 'collects info for processable workers' do
        expect(id_info.sort_entries('fakepath')[0]).to eq([%w[oldid1 112233]])
      end

      it 'collects workers needing confirmation' do
        expect(id_info.sort_entries('fakepath')[1])
          .to eq([['Lname2, Fname2', 'oldid2', '2@example.com']])
      end
    end
  end

  describe '#generate_csv' do
    subject(:id_info) { ConcurImporter::IdInformation.new }

    let(:filepath)  { Rails.root.to_s + '/tmp/concur/employee_fake_idinformation_20180214140000.txt' }
    let(:final_csv) do
      <<-CSV.strip_heredoc
      100,0,SSO,UPDATE,EN,N,N
      320,old_id_1,new_id_1,,,,,,
      320,old_id_2,new_id_2,,,,,,
      320,old_id_3,new_id_3,,,,,,
      320,old_id_4,new_id_4,,,,,,
      CSV
    end

    before do
      Timecop.freeze(Time.new(2018, 2, 14, 22, 0, 0, '+00:00'))
      CSV.open('tmp/concur/test.csv', 'w+:bom|utf-8') do |csv|
        csv << ['old_id_1','new_id_1']
        csv << ['old_id_2','new_id_2']
        csv << ['old_id_3','new_id_3']
        csv << ['old_id_4','new_id_4']
      end
      id_info.generate_csv(IO.readlines('tmp/concur/test.csv'))
    end

    after do
      Timecop.return
    end

    it 'creates an id information txt file' do
      expect(File.read(filepath)).to eq(final_csv)
    end
  end
end
