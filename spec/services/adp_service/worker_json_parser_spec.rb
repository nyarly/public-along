require 'rails_helper'

describe AdpService::WorkerJsonParser, type: :service do
  let(:json) { JSON.parse(File.read(Rails.root.to_s + '/spec/fixtures/adp_workers.json')) }

  describe '#sort_workers' do
    it 'calls gen_worker_hash for non-terminated workers' do
      # There are 3 workers indicated in the json file, one is terminated

      adp = AdpService::WorkerJsonParser.new

      expect(adp).to receive(:gen_worker_hash).exactly(2).times
      adp.sort_workers(json)
    end

    it 'returns worker array' do
      adp = AdpService::WorkerJsonParser.new

      expect(adp).to receive(:gen_worker_hash).twice.and_return({ worker: 'info' })
      expect(adp.sort_workers(json)).to eq([{ worker: 'info' }, { worker: 'info' }])
    end
  end

  describe '#gen_worker_hash' do
    let(:json)           { JSON.parse(File.read(Rails.root.to_s + '/spec/fixtures/adp_workers.json')) }
    let!(:manager)       { FactoryGirl.create(:active_profile, adp_employee_id: '101734') }
    let!(:worker_type)   { FactoryGirl.create(:worker_type, name: 'Regular Full-Time', code: 'FTR') }
    let!(:worker_type_2) { FactoryGirl.create(:worker_type, name: 'Voluntary', code: 'TVOL') }
    let!(:department)    { FactoryGirl.create(:department, name: 'People & Culture-HR & Total Rewards', code: '111000') }
    let!(:department_2)  { FactoryGirl.create(:department, name: 'Sales - General - Germany', code: '120710') }
    let!(:department_3)  { FactoryGirl.create(:department, name: 'Inside Sales', code: '125000') }
    let!(:location)      { FactoryGirl.create(:location, name: 'Las Vegas', code: 'LAS') }
    let!(:location_2)    { FactoryGirl.create(:location, name: 'Germany', code: 'GERMA', kind: 'Remote Location') }
    let!(:job_title)     { FactoryGirl.create(:job_title, name: 'Sr. People Business Partner', code: 'SRBP') }
    let!(:job_title_2)   { FactoryGirl.create(:job_title, name: 'Sales Representative, OTC', code: 'SROTC') }
    let!(:job_title_3)   { FactoryGirl.create(:job_title, name: 'Sales Associate', code: 'SADEN') }
    let!(:country)       { Country.find_or_create_by(iso_alpha_2: 'US') }
    let!(:germany)       { Country.find_or_create_by(iso_alpha_2: 'DE') }

    it 'creates the hash from json' do
      w_json = json['workers'][2]

      adp = AdpService::WorkerJsonParser.new

      expect(adp.gen_worker_hash(w_json)).to eq({
        adp_status: 'Active',
        adp_assoc_oid: 'G32B8JAXA1W398Z8',
        adp_employee_id: '101455',
        legal_first_name: 'Shirley',
        first_name: 'Shirley',
        last_name: 'Allansberg',
        personal_mobile_phone: '(212) 555-4411',
        office_phone: '(212) 555-4411',
        hire_date: '2013-08-05',
        contract_end_date: nil,
        start_date: '2013-08-05',
        end_date: nil,
        rehire_date: nil,
        company: 'OpenTable Inc.',
        job_title_id: job_title.id,
        worker_type_id: worker_type.id,
        manager_adp_employee_id: '101734',
        location_id: location.id,
        department_id: department.id,
        profile_status: 'active',
        business_card_title: 'Senior Backend Engineer, Restaurant Products',
        management_position: true,
        manager_id: manager.employee.id,
        payroll_file_number: '101455'
      })
    end

    context 'when worker has nickname' do
      it 'populates legal first name' do
        w_json = json['workers'][0]

        adp = AdpService::WorkerJsonParser.new

        expect(adp.gen_worker_hash(w_json)).to include({
          legal_first_name: 'Idina'
        })
      end

      it 'uses nickname for first name field' do
        w_json = json['workers'][0]

        adp = AdpService::WorkerJsonParser.new

        expect(adp.gen_worker_hash(w_json)).to include({
          first_name: 'Sally Jesse'
        })
      end
    end

    context 'when worker does not have nickname' do
      it 'populates legal first name' do
        w_json = json['workers'][1]

        adp = AdpService::WorkerJsonParser.new

        expect(adp.gen_worker_hash(w_json)).to include({
          legal_first_name: 'John'
        })
      end

      it 'uses legal name in first name field' do
        w_json = json['workers'][1]

        adp = AdpService::WorkerJsonParser.new

        expect(adp.gen_worker_hash(w_json)).to include({
          first_name: 'John'
        })
      end
    end

    context 'when worker has preferred last name' do
      it 'uses preferred last name' do
        w_json = json["workers"][0]

        adp = AdpService::WorkerJsonParser.new

        expect(adp.gen_worker_hash(w_json)).to include({
          last_name: "Smith"
        })
      end
    end

    context 'when worker does not have preferred last name' do
      it 'uses family name' do
        w_json = json['workers'][1]

        adp = AdpService::WorkerJsonParser.new

        expect(adp.gen_worker_hash(w_json)).to include({
          last_name: 'Roussimoff'
        })
      end
    end

    context 'when worker has worker end date' do
      it 'assigns a contract end date' do
        w_json = json['workers'][1]

        adp = AdpService::WorkerJsonParser.new

        expect(adp.gen_worker_hash(w_json)).to include({
          contract_end_date: '2017-01-20'
        })
      end
    end

    context 'when worker does not have worker end date' do
      it 'does not have a contract end date' do
        w_json = json['workers'][0]

        adp = AdpService::WorkerJsonParser.new

        expect(adp.gen_worker_hash(w_json)).to include({
          contract_end_date: nil
        })
      end
    end

    context 'when worker has business card title' do
      it 'assigns business card title' do
        w_json = json['workers'][2]

        adp = AdpService::WorkerJsonParser.new

        expect(adp.gen_worker_hash(w_json)).to include({
          business_card_title: 'Senior Backend Engineer, Restaurant Products'
        })
      end
    end

    context 'when worker does not have business card title' do
      it 'uses job title for business card title' do
        w_json = json['workers'][1]

        adp = AdpService::WorkerJsonParser.new

        expect(adp.gen_worker_hash(w_json)).to include({
          business_card_title: 'Sales Associate'
        })
      end
    end

    context 'when worker is remote' do
      it 'has worker address' do
        w_json = json['workers'][0]

        adp = AdpService::WorkerJsonParser.new

        expect(adp.gen_worker_hash(w_json)).to include({
          line_1: 'Zeukerstrasse 123',
          line_2: nil,
          city: 'Frankfurt',
          state_territory: 'Hessen',
          postal_code: '5384980',
          country_id: germany.id
        })
      end
    end

    context 'when worker is not remote' do
      it 'does not pull worker address' do
        w_json = json['workers'][1]

        adp = AdpService::WorkerJsonParser.new

        expect(adp.gen_worker_hash(w_json)).to_not include({
          line_1: '2890 Beach Blvd',
          line_2: 'Apt 222',
          city: 'Denver',
          state_territory: 'CO',
          postal_code: '63748',
          country_id: country.id
        })
      end
    end
  end
end
