
require "lib/logger"

unless defined? LOGGER
  if defined?(PROXYFS_ENV) && PROXYFS_ENV == :test
    LOGGER = ProxyFS::Logger.new File.expand_path(File.join(File.dirname(__FILE__), "../test.log"))
  else
    LOGGER = ProxyFS::Logger.new File.expand_path(File.join(File.dirname(__FILE__), "../status.log"))
  end
end

