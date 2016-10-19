module DateTimeHelper
  class FileTime
    # Convert the time to the FILETIME format, a 64-bit value representing the
    # number of 100-nanosecond intervals since January 1, 1601 (UTC).

    # Active Directory requires this in a string format
    def self.wtime(datetime)
      (datetime.to_i * 10000000 + 116444736000000000).to_s
    end

    def self.to_datetime(filetime)
      int = (filetime.to_i - 116444736000000000)/10000000
      Time.at(int).to_datetime
    end
  end
end
