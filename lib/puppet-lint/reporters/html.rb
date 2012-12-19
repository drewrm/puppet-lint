require 'erb'
require 'ostruct'

class PuppetLint
  class Reporters
    class Html < PuppetLint::Reporter
      def report
        namespace = OpenStruct.new({
          :messages => @messages,
          :context  => @configuration.with_context,
          :warnings => @statistics[:warning],
          :errors   => @statistics[:error]
        })
        template = ERB.new File.new(File.join(File.dirname(__FILE__), "templates/html.erb")).read, nil, "%"
        puts template.result(namespace.send(:binding))
      end
    end
  end
end
