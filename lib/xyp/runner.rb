require "optparse"
require "ostruct"

require_relative "version"
require_relative "gui"

module XYP

  class Runner
    attr_accessor :options

    def initialize
      @options={}
    end

    def self.run *arguments
      new.run(arguments)
    end

    def run arguments
      options = parse_options(arguments)
      gui options
    end

    private
    def parse_options(arguments)

      size=arguments.size

      parser = OptionParser.new

      options = {}

      parser.on("-h", "--help", "Show help message") do
        puts parser
        exit(true)
      end

      parser.on("-v", "--version", "Show version number") do
        puts VERSION
        exit(true)
      end

      parser.on("-d", "--data FILE", "data file>") do |file|
        options[:data_file] = file
      end

      parser.parse!(arguments)

      if size==0
        puts parser
      end

      options
    end

    def gui options
      gui = GUI.new #(glade_file)
      gui.run(options)
    end

  end
end
