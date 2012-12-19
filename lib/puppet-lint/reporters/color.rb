require 'colorize'

class PuppetLint
  class Reporters
    class Color < PuppetLint::Reporter
      def report
        @messages.each { |file, msgs|
          msgs.each { |m|
            output = format % m
            output = output.red if m[:KIND] == "ERROR"
            puts output
            puts m[:context] if m[:context] && @configuration.with_context
          }
        }
      end
    end
  end
end
