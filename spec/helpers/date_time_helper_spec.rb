require 'rails_helper'

describe DateTimeHelper, type: :helper do
  before :each do
    Timecop.freeze(Time.new(2016, 6, 13, 0, 0, 0, "-07:00"))
  end

  after :each do
    Timecop.return
  end

  describe "FileTime.wtime(datetime)" do
    it "should convert DateTime to FileTime string" do
      expect(DateTimeHelper::FileTime.wtime(DateTime.now)).to be_a(String)
      expect(DateTimeHelper::FileTime.wtime(DateTime.now)).to eq("131102748000000000")
    end
  end

  describe "FileTime.to_datetime(filetime)" do
    it "should convert FileTime to DateTime object" do
      expect(DateTimeHelper::FileTime.to_datetime("131304852000000000")).to be_a(DateTime)
      expect(DateTimeHelper::FileTime.to_datetime("131304852000000000")).to eq(DateTime.new(2017, 2, 1, 21).change(:offset => "-0800"))
    end
  end
end
