
require "log4r"

module ProxyFS
  LOGGER = Log4r::Logger.new "proxyfs"
  LOGGER.outputters = Log4r::FileOutputter.new("proxyfs", :filename => File.join(File.dirname(__FILE__), "/../../log/error.log"))

  class Try
    def self.to(label = "", options = {})
      opts = { :times => 1 }.merge options

      opts[:times].times do |i|
        LOGGER.info label

        begin
          return yield
        rescue
          LOGGER.error label

          if i == opts[:times]
            return false
          else
            wait = opts[:wait][i] rescue 0

            LOGGER.info "wait for #{wait} seconds"

            sleep wait
          end
        end
      end
    end
  end
end

