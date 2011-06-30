
require "action_mailer"
require "config/mailer"
require "timeout"
require "thread"

module ProxyFS
  class Mailer < ActionMailer::Base
    def notification(mode, str)
      subject "ProxyFS: #{mode}"

      part :body => str
    end
  end

  class Logger
    def initialize(file)
      @file = open(file, "w+")

      @mutex = Mutex.new
    end

    def info(str)
      log("info", str)
    end

    def error(str)
      notify("error", str)
    end

    def fatal(str)
      notify("fatal", str)
    end

    private

    def notify(mode, str)
      Timeout::timeout(3) do
        Mailer.deliver_notification(mode, str)
      end

      log(mode, str)
    rescue Exception
      false
    end

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

