module ActiveDirectory
  class Result
    def self.call(result)
      return result if pass?(result)
      Proc.new.call if block_given?
    end

    def self.pass?(result)
      code = result.code
      code == 0 || code == 68
    end
  end
end
