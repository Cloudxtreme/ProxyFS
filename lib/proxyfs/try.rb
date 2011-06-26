
require "log4r"

module ProxyFS
  class Try
    @@logger = Log4r::Logger.new "proxyfs"
    @@logger.outputters = Log4r::FileOutputter.new("proxyfs", :filename => File.join(File.dirname(__FILE__), "/../../log/error.log"))

    def self.logger
      @@logger
    end

    def self.to(label = "", options = {})
      opts = { :times => 1 }.merge options

      opts[:times].times do |i|
        @@logger.info label

        begin
          return yield
        rescue Exception => e
          @@logger.error label

          if i >= opts[:times]
            return false
          else
            wait = opts[:wait][i] rescue 0

            @@logger.info "wait for #{wait} seconds"

            sleep wait
          end
        end
      end

      @@logger.error "#{label}: aborted"

      false
    end
  end
end

