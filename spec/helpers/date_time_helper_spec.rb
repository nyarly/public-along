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
end
