
require File.join(File.dirname(__FILE__), "../config/test")

require "test/unit/ui/console/testrunner"
require "test/unit/testsuite"
require "test/units/error_handler_test"
require "test/units/garbage_collector_test"
require "test/units/logger_test"
require "test/units/mirror_test"
require "test/units/mirrors_test"
require "test/units/mirror_worker_test"
require "test/units/rand32_test"
require "test/units/task_test"
require "test/units/fuse_test"

class TestSuite
  def self.suite
    suite = Test::Unit::TestSuite.new "ProxyFS"

    suite << ErrorHandlerTest.suite
    suite << GarbageCollectorTest.suite
    suite << LoggerTest.suite
    suite << MirrorTest.suite
    suite << MirrorsTest.suite
    suite << MirrorWorkerTest.suite
    suite << Rand32Test.suite
    suite << TaskTest.suite
    suite << FuseTest.suite

    suite
  end
end

Test::Unit::UI::Console::TestRunner.run TestSuite

