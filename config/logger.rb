
require File.expand_path File.join(File.dirname(__FILE__), "../lib/logger")

LOGGER = ProxyFS::Logger.new :path => File.expand_path(File.join(File.dirname(__FILE__), "../status.log"))

