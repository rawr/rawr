module CustomFileMatchers
  class BeExistingFile
    def initialize; end

    def matches?(target)
      @target = target
      File.exists? @target
    end

    def failure_message
      "expected existing file #{@target.inspect}"
    end

    def negative_failure_message
      "expected no existing file #{@target.inspect}"
    end
  end
  
  def be_existing_file
    BeExistingFile.new
  end
end
