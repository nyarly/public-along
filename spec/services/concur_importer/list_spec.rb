require 'rails_helper'

describe ConcurImporter::List, type: :service do
  before do
    dirname = 'tmp/concur'
    FileUtils.mkdir_p(dirname) unless File.directory?(dirname)

    Dir["#{dirname}/*"].each do |f|
      File.delete(f)
    end
  end

  after do
    Dir["tmp/concur/*"].each do |f|
      File.delete(f)
    end
  end

  describe '#department_list' do
    let(:filename)  { "/tmp/concur/list_fake_department_#{Time.now.strftime('%Y%m%d%H%M%S')}.txt" }
    let(:service)   { ConcurImporter::List.new }
    let(:filepath)  { Rails.root.to_s + filename }

    let(:csv) do
      <<-EOS.strip_heredoc
      Department,Department,044000,,,,,,,,,,BizOpti/Internal System Engineering,20180101,,N
      Department,Department,050000,,,,,,,,,,Brand/General Marketing,20180101,,N
      Department,Department,070000,,,,,,,,,,Business Development,20180101,,N
      Department,Department,051000,,,,,,,,,,Consumer Marketing,20180101,,N
      Department,Department,062000,,,,,,,,,,Consumer Product Management,20180101,,N
      Department,Department,032000,,,,,,,,,,Customer Support,20180101,,N
      Department,Department,045000,,,,,,,,,,Data Analytics & Experimentation,20180101,,N
      Department,Department,046000,,,,,,,,,,Data Science,20180101,,N
      Department,Department,063000,,,,,,,,,,Design,20180101,,N
      Department,Department,018000,,,,,,,,,,Executive,20180101,,N
      Department,Department,010000,,,,,,,,,,Facilities,20180101,,N
      Department,Department,031000,,,,,,,,,,Field Operations,20180101,,N
      Department,Department,013000,,,,,,,,,,Finance,20180101,,N
      Department,Department,019000,,,,,,,,,,Finance Operations,20180101,,N
      Department,Department,036000,,,,,,,,,,Infrastructure Engineering,20180101,,N
      Department,Department,025000,,,,,,,,,,Inside Sales,20180101,,N
      Department,Department,012000,,,,,,,,,,Legal,20180101,,N
      Department,Department,011000,,,,,,,,,,People & Culture-HR & Total Rewards,20180101,,N
      Department,Department,017000,,,,,,,,,,People & Culture-Talent Acquisition,20180101,,N
      Department,Department,043000,,,,,,,,,,Product Engineering - Back End,20180101,,N
      Department,Department,041000,,,,,,,,,,Product Engineering - Front End Diner,20180101,,N
      Department,Department,042000,,,,,,,,,,Product Engineering - Front End Restaurant,20180101,,N
      Department,Department,054000,,,,,,,,,,Product Marketing,20180101,,N
      Department,Department,053000,,,,,,,,,,Public Relations,20180101,,N
      Department,Department,052000,,,,,,,,,,Restaurant Marketing,20180101,,N
      Department,Department,061000,,,,,,,,,,Restaurant Product Management,20180101,,N
      Department,Department,033000,,,,,,,,,,Restaurant Relations Management,20180101,,N
      Department,Department,014000,,,,,,,,,,Risk Management,20180101,,N
      Department,Department,020000,,,,,,,,,,Sales,20180101,,N
      Department,Department,021000,,,,,,,,,,Sales Operations,20180101,,N
      Department,Department,040000,,,,,,,,,,Technology/CTO Admin,20180101,,N
      Department,Department,035000,,,,,,,,,,Tech Table,20180101,,N
      EOS
    end

    it 'has the correct data' do
      service.department_list
      expect(File.read(filepath)).to eq(csv)
    end
  end

  describe '#location_list' do
    let(:filename)  { "/tmp/concur/list_fake_location_#{Time.now.strftime('%Y%m%d%H%M%S')}.txt" }
    let(:service)   { ConcurImporter::List.new }
    let(:filepath)  { Rails.root.to_s + filename }

    let(:csv) do
      <<-EOS.strip_heredoc
      Location,Location,AB,,,,,,,,,,Alberta,20180101,,N
      Location,Location,AZ,,,,,,,,,,Arizona,20180101,,N
      Location,Location,BER,,,,,,,,,,Berlin,20180101,,N
      Location,Location,BM,,,,,,,,,,Birmingham,20180101,,N
      Location,Location,BZ,,,,,,,,,,Bristol,20180101,,N
      Location,Location,BC,,,,,,,,,,British Columbia,20180101,,N
      Location,Location,CUN,,,,,,,,,,Cancun,20180101,,N
      Location,Location,CHI,,,,,,,,,,Chicago Office,20180101,,N
      Location,Location,CO,,,,,,,,,,Colorado,20180101,,N
      Location,Location,CDC,,,,,,,,,,Concord Distribution Center,20180101,,N
      Location,Location,CONTR,,,,,,,,,,CONTRACT,20180101,,N
      Location,Location,COR,,,,,,,,,,Corby,20180101,,N
      Location,Location,DCC,,,,,,,,,,Denver Contact Center,20180101,,N
      Location,Location,DENCS,,,,,,,,,,Denver CSR,20180101,,N
      Location,Location,DEN,,,,,,,,,,Denver Office,20180101,,N
      Location,Location,DND,,,,,,,,,,Dundee,20180101,,N
      Location,Location,EB,,,,,,,,,,Edinburgh,20180101,,N
      Location,Location,FL,,,,,,,,,,Florida,20180101,,N
      Location,Location,FRA,,,,,,,,,,Frankfurt Office,20180101,,N
      Location,Location,GA,,,,,,,,,,Georgia,20180101,,N
      Location,Location,GLA,,,,,,,,,,Glasgow,20180101,,N
      Location,Location,HAM,,,,,,,,,,Hamburg,20180101,,N
      Location,Location,HI,,,,,,,,,,Hawaii,20180101,,N
      Location,Location,ID,,,,,,,,,,Idaho,20180101,,N
      Location,Location,IL,,,,,,,,,,Illinois,20180101,,N
      Location,Location,IRL,,,,,,,,,,Ireland,20180101,,N
      Location,Location,KY,,,,,,,,,,Kentucky,20180101,,N
      Location,Location,LD,,,,,,,,,,Leeds,20180101,,N
      Location,Location,LON,,,,,,,,,,London Office,20180101,,N
      Location,Location,LOS,,,,,,,,,,Los Angeles Office,20180101,,N
      Location,Location,LA,,,,,,,,,,Louisiana,20180101,,N
      Location,Location,ME,,,,,,,,,,Maine,20180101,,N
      Location,Location,MAN,,,,,,,,,,Manchester,20180101,,N
      Location,Location,MD,,,,,,,,,,Maryland,20180101,,N
      Location,Location,MA,,,,,,,,,,Massachusetts,20180101,,N
      Location,Location,MEL,,,,,,,,,,Melbourne Office,20180101,,N
      Location,Location,MXC,,,,,,,,,,Mexico City Office,20180101,,N
      Location,Location,MI,,,,,,,,,,Michigan,20180101,,N
      Location,Location,MN,,,,,,,,,,Minnesota,20180101,,N
      Location,Location,MO,,,,,,,,,,Missouri,20180101,,N
      Location,Location,MUM,,,,,,,,,,Mumbai Office,20180101,,N
      Location,Location,MUN,,,,,,,,,,Munich,20180101,,N
      Location,Location,NE,,,,,,,,,,Nebraska,20180101,,N
      Location,Location,NV,,,,,,,,,,Nevada,20180101,,N
      Location,Location,NJ,,,,,,,,,,New Jersey,20180101,,N
      Location,Location,NSW,,,,,,,,,,New South Wales,20180101,,N
      Location,Location,NY,,,,,,,,,,New York,20180101,,N
      Location,Location,NYC,,,,,,,,,,New York City Office,20180101,,N
      Location,Location,NC,,,,,,,,,,North Carolina,20180101,,N
      Location,Location,NCA,,,,,,,,,,Northern California,20180101,,N
      Location,Location,OH,,,,,,,,,,Ohio,20180101,,N
      Location,Location,ON,,,,,,,,,,Ontario,20180101,,N
      Location,Location,OR,,,,,,,,,,Oregon,20180101,,N
      Location,Location,PA,,,,,,,,,,Pennsylvania,20180101,,N
      Location,Location,POW,,,,,,,,,,Powai,20180101,,N
      Location,Location,QC,,,,,,,,,,Quebec,20180101,,N
      Location,Location,QLD,,,,,,,,,,Queensland,20180101,,N
      Location,Location,SF,,,,,,,,,,San Francisco Headquarters,20180101,,N
      Location,Location,SC,,,,,,,,,,South Carolina,20180101,,N
      Location,Location,SCA,,,,,,,,,,Southern California,20180101,,N
      Location,Location,SY,,,,,,,,,,Sydney,20180101,,N
      Location,Location,TN,,,,,,,,,,Tennessee,20180101,,N
      Location,Location,TX,,,,,,,,,,Texas,20180101,,N
      Location,Location,TYO,,,,,,,,,,Tokyo Office,20180101,,N
      Location,Location,UT,,,,,,,,,,Utah,20180101,,N
      Location,Location,VT,,,,,,,,,,Vermont,20180101,,N
      Location,Location,VIC,,,,,,,,,,Victoria,20180101,,N
      Location,Location,WA,,,,,,,,,,Washington,20180101,,N
      Location,Location,WI,,,,,,,,,,Wisconsin,20180101,,N
      EOS
    end

    it 'has the correct data' do
      service.location_list
      expect(File.read(filepath)).to eq(csv)
    end
  end
end
