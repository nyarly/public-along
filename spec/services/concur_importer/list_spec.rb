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

  describe '#departments' do
    let(:filename)  { "/tmp/concur/list_fake_departments_#{Time.now.strftime('%Y%m%d%H%M%S')}.txt" }
    let(:service)   { ConcurImporter::List.new }
    let(:filepath)  { Rails.root.to_s + filename }

    let(:csv) do
      <<-EOS.strip_heredoc
      Departments,ConcurLists,044000,,,,,,,,,,BizOpti/Internal System Engineering,20180101,,N
      Departments,ConcurLists,050000,,,,,,,,,,Brand/General Marketing,20180101,,N
      Departments,ConcurLists,070000,,,,,,,,,,Business Development,20180101,,N
      Departments,ConcurLists,051000,,,,,,,,,,Consumer Marketing,20180101,,N
      Departments,ConcurLists,062000,,,,,,,,,,Consumer Product Management,20180101,,N
      Departments,ConcurLists,032000,,,,,,,,,,Customer Support,20180101,,N
      Departments,ConcurLists,045000,,,,,,,,,,Data Analytics & Experimentation,20180101,,N
      Departments,ConcurLists,046000,,,,,,,,,,Data Science,20180101,,N
      Departments,ConcurLists,063000,,,,,,,,,,Design,20180101,,N
      Departments,ConcurLists,018000,,,,,,,,,,Executive,20180101,,N
      Departments,ConcurLists,010000,,,,,,,,,,Facilities,20180101,,N
      Departments,ConcurLists,031000,,,,,,,,,,Field Operations,20180101,,N
      Departments,ConcurLists,013000,,,,,,,,,,Finance,20180101,,N
      Departments,ConcurLists,019000,,,,,,,,,,Finance Operations,20180101,,N
      Departments,ConcurLists,036000,,,,,,,,,,Infrastructure Engineering,20180101,,N
      Departments,ConcurLists,025000,,,,,,,,,,Inside Sales,20180101,,N
      Departments,ConcurLists,012000,,,,,,,,,,Legal,20180101,,N
      Departments,ConcurLists,011000,,,,,,,,,,People & Culture-HR & Total Rewards,20180101,,N
      Departments,ConcurLists,017000,,,,,,,,,,People & Culture-Talent Acquisition,20180101,,N
      Departments,ConcurLists,043000,,,,,,,,,,Product Engineering - Back End,20180101,,N
      Departments,ConcurLists,041000,,,,,,,,,,Product Engineering - Front End Diner,20180101,,N
      Departments,ConcurLists,042000,,,,,,,,,,Product Engineering - Front End Restaurant,20180101,,N
      Departments,ConcurLists,054000,,,,,,,,,,Product Marketing,20180101,,N
      Departments,ConcurLists,053000,,,,,,,,,,Public Relations,20180101,,N
      Departments,ConcurLists,052000,,,,,,,,,,Restaurant Marketing,20180101,,N
      Departments,ConcurLists,061000,,,,,,,,,,Restaurant Product Management,20180101,,N
      Departments,ConcurLists,033000,,,,,,,,,,Restaurant Relations Management,20180101,,N
      Departments,ConcurLists,014000,,,,,,,,,,Risk Management,20180101,,N
      Departments,ConcurLists,020000,,,,,,,,,,Sales,20180101,,N
      Departments,ConcurLists,021000,,,,,,,,,,Sales Operations,20180101,,N
      Departments,ConcurLists,040000,,,,,,,,,,Technology/CTO Admin,20180101,,N
      Departments,ConcurLists,035000,,,,,,,,,,Tech Table,20180101,,N
      EOS
    end

    it 'has the correct data' do
      service.departments
      expect(File.read(filepath)).to eq(csv)
    end
  end

  describe '#locations' do
    let(:filename)  { "/tmp/concur/list_fake_locations_#{Time.now.strftime('%Y%m%d%H%M%S')}.txt" }
    let(:service)   { ConcurImporter::List.new }
    let(:filepath)  { Rails.root.to_s + filename }

    let(:csv) do
      <<-EOS.strip_heredoc
      Locations,ConcurLists,AB,,,,,,,,,,Alberta,20180101,,N
      Locations,ConcurLists,AZ,,,,,,,,,,Arizona,20180101,,N
      Locations,ConcurLists,BER,,,,,,,,,,Berlin,20180101,,N
      Locations,ConcurLists,BM,,,,,,,,,,Birmingham,20180101,,N
      Locations,ConcurLists,BZ,,,,,,,,,,Bristol,20180101,,N
      Locations,ConcurLists,BC,,,,,,,,,,British Columbia,20180101,,N
      Locations,ConcurLists,CUN,,,,,,,,,,Cancun,20180101,,N
      Locations,ConcurLists,CHI,,,,,,,,,,Chicago Office,20180101,,N
      Locations,ConcurLists,CO,,,,,,,,,,Colorado,20180101,,N
      Locations,ConcurLists,CDC,,,,,,,,,,Concord Distribution Center,20180101,,N
      Locations,ConcurLists,CONTR,,,,,,,,,,CONTRACT,20180101,,N
      Locations,ConcurLists,COR,,,,,,,,,,Corby,20180101,,N
      Locations,ConcurLists,DCC,,,,,,,,,,Denver Contact Center,20180101,,N
      Locations,ConcurLists,DENCS,,,,,,,,,,Denver CSR,20180101,,N
      Locations,ConcurLists,DEN,,,,,,,,,,Denver Office,20180101,,N
      Locations,ConcurLists,DND,,,,,,,,,,Dundee,20180101,,N
      Locations,ConcurLists,EB,,,,,,,,,,Edinburgh,20180101,,N
      Locations,ConcurLists,FL,,,,,,,,,,Florida,20180101,,N
      Locations,ConcurLists,FRA,,,,,,,,,,Frankfurt Office,20180101,,N
      Locations,ConcurLists,GA,,,,,,,,,,Georgia,20180101,,N
      Locations,ConcurLists,GLA,,,,,,,,,,Glasgow,20180101,,N
      Locations,ConcurLists,HAM,,,,,,,,,,Hamburg,20180101,,N
      Locations,ConcurLists,HI,,,,,,,,,,Hawaii,20180101,,N
      Locations,ConcurLists,ID,,,,,,,,,,Idaho,20180101,,N
      Locations,ConcurLists,IL,,,,,,,,,,Illinois,20180101,,N
      Locations,ConcurLists,IRL,,,,,,,,,,Ireland,20180101,,N
      Locations,ConcurLists,KY,,,,,,,,,,Kentucky,20180101,,N
      Locations,ConcurLists,LD,,,,,,,,,,Leeds,20180101,,N
      Locations,ConcurLists,LON,,,,,,,,,,London Office,20180101,,N
      Locations,ConcurLists,LOS,,,,,,,,,,Los Angeles Office,20180101,,N
      Locations,ConcurLists,LA,,,,,,,,,,Louisiana,20180101,,N
      Locations,ConcurLists,ME,,,,,,,,,,Maine,20180101,,N
      Locations,ConcurLists,MAN,,,,,,,,,,Manchester,20180101,,N
      Locations,ConcurLists,MD,,,,,,,,,,Maryland,20180101,,N
      Locations,ConcurLists,MA,,,,,,,,,,Massachusetts,20180101,,N
      Locations,ConcurLists,MEL,,,,,,,,,,Melbourne Office,20180101,,N
      Locations,ConcurLists,MXC,,,,,,,,,,Mexico City Office,20180101,,N
      Locations,ConcurLists,MI,,,,,,,,,,Michigan,20180101,,N
      Locations,ConcurLists,MN,,,,,,,,,,Minnesota,20180101,,N
      Locations,ConcurLists,MO,,,,,,,,,,Missouri,20180101,,N
      Locations,ConcurLists,MUM,,,,,,,,,,Mumbai Office,20180101,,N
      Locations,ConcurLists,MUN,,,,,,,,,,Munich,20180101,,N
      Locations,ConcurLists,NE,,,,,,,,,,Nebraska,20180101,,N
      Locations,ConcurLists,NV,,,,,,,,,,Nevada,20180101,,N
      Locations,ConcurLists,NJ,,,,,,,,,,New Jersey,20180101,,N
      Locations,ConcurLists,NSW,,,,,,,,,,New South Wales,20180101,,N
      Locations,ConcurLists,NY,,,,,,,,,,New York,20180101,,N
      Locations,ConcurLists,NYC,,,,,,,,,,New York City Office,20180101,,N
      Locations,ConcurLists,NC,,,,,,,,,,North Carolina,20180101,,N
      Locations,ConcurLists,NCA,,,,,,,,,,Northern California,20180101,,N
      Locations,ConcurLists,OH,,,,,,,,,,Ohio,20180101,,N
      Locations,ConcurLists,ON,,,,,,,,,,Ontario,20180101,,N
      Locations,ConcurLists,OR,,,,,,,,,,Oregon,20180101,,N
      Locations,ConcurLists,PA,,,,,,,,,,Pennsylvania,20180101,,N
      Locations,ConcurLists,POW,,,,,,,,,,Powai,20180101,,N
      Locations,ConcurLists,QC,,,,,,,,,,Quebec,20180101,,N
      Locations,ConcurLists,QLD,,,,,,,,,,Queensland,20180101,,N
      Locations,ConcurLists,SF,,,,,,,,,,San Francisco Headquarters,20180101,,N
      Locations,ConcurLists,SC,,,,,,,,,,South Carolina,20180101,,N
      Locations,ConcurLists,SCA,,,,,,,,,,Southern California,20180101,,N
      Locations,ConcurLists,SY,,,,,,,,,,Sydney,20180101,,N
      Locations,ConcurLists,TN,,,,,,,,,,Tennessee,20180101,,N
      Locations,ConcurLists,TX,,,,,,,,,,Texas,20180101,,N
      Locations,ConcurLists,TYO,,,,,,,,,,Tokyo Office,20180101,,N
      Locations,ConcurLists,UT,,,,,,,,,,Utah,20180101,,N
      Locations,ConcurLists,VT,,,,,,,,,,Vermont,20180101,,N
      Locations,ConcurLists,VIC,,,,,,,,,,Victoria,20180101,,N
      Locations,ConcurLists,WA,,,,,,,,,,Washington,20180101,,N
      Locations,ConcurLists,WI,,,,,,,,,,Wisconsin,20180101,,N
      EOS
    end

    it 'has the correct data' do
      service.locations
      expect(File.read(filepath)).to eq(csv)
    end
  end
end
