
require "log4r"

LOGGER = Log4r::Logger.new "proxyfs"
LOGGER.outputters = Log4r::FileOutputter.new("proxyfs", :filename => File.join(File.dirname(__FILE__), "../status.log"))

