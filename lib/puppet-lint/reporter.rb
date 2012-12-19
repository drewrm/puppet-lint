class PuppetLint
  class Reporter
    attr_accessor :format, :statistics, :configuration

    def initialize
      @statistics = {:error => 0, :warning => 0}
      @messages = {}
    end

    def add_message(message)
      @messages[message[:path]] = [] if @messages[message[:path]].nil?
      @messages[message[:path]] << message
    end

    def report
      @messages.each { |file, msgs|
        msgs = msgs.sort { |a,b| a[:linenumber] <=> b[:linenumber] }
        msgs.each { |m|
          puts format % m
          puts m[:context] if m[:context] && @configuration.with_context
        }
      }
    end
  end
end
