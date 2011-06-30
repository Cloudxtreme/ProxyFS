
require "lib/logger"

LOGGER = ProxyFS::Logger.new File.expand_path(File.join(File.dirname(__FILE__), "../status.log")) unless defined? LOGGER

