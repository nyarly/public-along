require 'rails_helper'

describe ConcurImporter::ImportSettings, type: :service do
  before :each do
    Dir['tmp/concur/*'].each do |f|
      File.delete(f)
    end

    dirname = 'tmp/concur'
    unless File.directory?(dirname)
      FileUtils.mkdir_p(dirname)
    end
  end

  after :each do
    Dir['tmp/concur/*'].each do |f|
      File.delete(f)
    end
  end

  describe 'import settings csv' do
    let(:filename)        { "/tmp/concur/import_settings_fake_#{DateTime.now.strftime('%Y%m%d%H%M%S')}.txt" }
    let(:service)         { ConcurImporter::ImportSettings.new }
    let(:filepath)        { Rails.root.to_s + filename }
    let(:generated_file)  {
      <<-EOS.strip_heredoc
      100,0,SSO,UPDATE,en_US,Y,Y
      EOS
    }

    it 'has the correct data' do
      service.generate_csv
      expect(File.read(filepath)).to eq(generated_file)
    end
  end
end
