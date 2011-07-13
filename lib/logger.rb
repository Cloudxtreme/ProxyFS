
require "action_mailer"
require "config/mailer"
require "timeout"
require "thread"

module ProxyFS
  # Sends out log messages as email notifications.
  #
  #   Mailer.deliver_notification("error", "an error has occurred")

  class Mailer < ActionMailer::Base
    def notification(level, str)
      subject "ProxyFS: #{level}"

      part :body => str
    end
  end

  # Write log messages to a log file and sends out an email, depending on the log level.
  #
  #   logger = Logger.new "/path/to/logfile"
  #   logger.error "an error has occurred"
  #
  # Don't mix up +Logger+ with replication logging done by ProxyFS.
  # +Logger+ writes plain old debug or error messages to a log file.

  class Logger
    # Creates a new +Logger+ object to write log messages into a file located at +file+.

    def initialize(file)
      @file = file

      @stream = open(@file, "a")

      @mutex = Mutex.new
    end

    # Returns the number of lines within the log file.

    def size
      @mutex.synchronize { File.read(@file).lines.count }
    end

    # Writes log message +str+ of log level +info+.

    def info(str)
      log("info", str)
    end

    # Send/write notification +str+ of log level +error+.

    def error(str)
      notify("error", str)
    end

    # Send/write notification +str+ of log level +fatal+.

    def fatal(str)
      notify("fatal", str)
    end

    private

    # Writes +str+ of log level +level+ and sends out an email.

    def notify(level, str)
      Timeout::timeout(3) do
        Mailer.deliver_notification(level, str)
      end

      log(level, str)
    rescue Exception
      false
    end

    # Writes log message +str+ of log level +level+.

    def log(level, str)
      @mutex.synchronize do
        begin
          @stream.puts "#{Time.now} #{level}: #{str}"
          @stream.flush
        rescue Exception
          false
        end
      end

      true
    end
  end
end

