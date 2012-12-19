require 'puppet-lint/version'
require 'puppet-lint/lexer'
require 'puppet-lint/configuration'
require 'puppet-lint/checks'
require 'puppet-lint/bin'
require 'puppet-lint/monkeypatches'
require 'puppet-lint/reporters'

class PuppetLint::NoCodeError < StandardError; end

class PuppetLint
  # Public: Gets/Sets the String manifest code to be checked.
  attr_accessor :code

  # Public: Initialise a new PuppetLint object.
  def initialize
    @code = nil
    @fileinfo = {:path => ''}
  end


  # Public: Access PuppetLint's configuration from outside the class.
  #
  # Returns a PuppetLint::Configuration object.
  def self.configuration
    @configuration ||= PuppetLint::Configuration.new
  end

  def reporter
    clazz = ["PuppetLint", "Reporters", configuration.output_format.to_s.capitalize].inject(Object) {|obj,c| obj.const_get c}
    @reporter ||= clazz.new
  end

  # Public: Access PuppetLint's configuration from inside the class.
  #
  # Returns a PuppetLint::Configuration object.
  def configuration
    self.class.configuration
  end

  # Public: Set the path of the manifest file to be tested and read the
  # contents of the file.
  #
  # Returns nothing.
  def file=(path)
    if File.exist? path
      @fileinfo[:path] = path
      @fileinfo[:fullpath] = File.expand_path(path)
      @fileinfo[:filename] = File.basename(path)
      @code = File.read(path)
    end
  end

  # Internal: Retrieve the format string to be used when writing problems to
  # STDOUT.  If the user has not specified a custom log format, build one for
  # them.
  #
  # Returns a format String to be used with String#%.
  def log_format
    if configuration.log_format == ''
      ## recreate previous old log format as far as thats possible.
      format = '%{KIND}: %{message} on line %{linenumber}'
      if configuration.with_filename
        format.prepend '%{path} - '
      end
      configuration.log_format = format
    end
    return configuration.log_format
  end

  # Internal: Print out the line of the manifest on which the problem was found
  # as well as a marker pointing to the location on the line.
  #
  # message - A Hash containing all the information about a problem.
  # linter  - The PuppetLint::Checks object that was used to test the manifest.
  #
  # Returns nothing.
  def get_context(message, linter)
    # XXX: I don't really like the way this has been implemented (passing the
    # linter object down through layers of functions.  Refactor me!
    return if message[:check] == 'documentation'
    line = linter.manifest_lines[message[:linenumber] - 1]
    offset = line.index(/\S/)
    sprintf "\n  #{line.strip}\n%#{message[:column] + 2 - offset}s\n\n", "^"
  end

  # Internal: collect the reported problems into a reporter
  #
  # problems - An Array of problem Hashes as returned by
  #            PuppetLint::Checks#run.
  # linter   - The PuppetLint::Checks object that was used to test the
  #            manifest.
  #
  # Returns nothing.
  def report(problems, linter)
    reporter.format = log_format
    reporter.configuration = configuration
    problems.each do |message|
      reporter.statistics[message[:kind]] += 1
      message.merge!(@fileinfo) {|key, v1, v2| v1 }
      message[:KIND] = message[:kind].to_s.upcase

      if [message[:kind], :all].include? configuration.error_level
        message[:context] = get_context(message, linter)
        reporter.add_message message
      end
    end
  end

  # Public: Determine if PuppetLint found any errors in the manifest.
  #
  # Returns true if errors were found, otherwise returns false.
  def errors?
    reporter.statistics[:error] != 0
  end

  # Public: Determine if PuppetLint found any warnings in the manifest.
  #
  # Returns true if warnings were found, otherwise returns false.
  def warnings?
    reporter.statistics[:warning] != 0
  end

  # Public: Run the loaded manifest code through the lint checks and print the
  # results of the checks to stdout.
  #
  # Returns nothing.
  # Raises PuppetLint::NoCodeError if no manifest code has been loaded.
  def run
    if @code.nil?
      raise PuppetLint::NoCodeError
    end

    linter = PuppetLint::Checks.new
    problems = linter.run(@fileinfo, @code)
    report problems, linter
  end

  # Public: print out the reporter to stdout
  # returns nothing.
  def print_report
    reporter.report
  end
end

# Default configuration options
PuppetLint.configuration.defaults

require 'puppet-lint/plugins'
