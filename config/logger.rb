
require "lib/logger"

unless defined? LOGGER
  if PROXYFS_ENV == :test
    LOGGER = ProxyFS::Logger.new File.join(File.dirname(__FILE__), "../log/test.log")
  else
    LOGGER = ProxyFS::Logger.new File.join(File.dirname(__FILE__), "../log/status.log")
  end
end

