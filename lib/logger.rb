
require "thread"

module ProxyFS
  class Logger
    def initialize(config)
      @file = open(config[:path], "w+")

      @mutex = Mutex.new
    end

    def info(str)
      log("info", str)
    end

    def error(str)
      log("error", str)
    end

    def fatal(str)
      log("fatal", str)
    end

    private

    def log(mode, str)
      @mutex.synchronize do
        begin
          @file.puts "#{mode}: #{str}"

          puts "#{mode}: #{str}"
        rescue Exception
          false
        end
      end

      true
    end
  end
end

