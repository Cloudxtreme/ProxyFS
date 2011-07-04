
require "lib/logger"

unless defined? LOGGER
  if PROXYFS_ENV == :test
    LOGGER = ProxyFS::Logger.new File.join(PROXYFS_ROOT, "log/test.log")
  else
    LOGGER = ProxyFS::Logger.new File.join(PROXYFS_ROOT, "log/status.log")
  end
end

