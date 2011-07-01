
require "test/lib/test_case"
require "test/units/fixtures"
require "lib/garbage_collector"
require "fileutils"

module ProxyFS
  class GarbageCollector
    @@timeout = 0.1
  end
end

class GarbageCollectorTest < ProxyFS::TestCase
  def setup
    setup_fixtures

    ProxyFS::GarbageCollector.instance.collect!
  end

  def test_collect!
    path = File.join(File.dirname(__FILE__), "../../log/test.bin")

    FileUtils.touch path

    sleep 1

    assert !File.exists?(path)
  end

  def test_no_collect!
    ProxyFS::Task.create :command => "test", :mirror => fixture(:mirror), :path => "/test.txt", :file => "keep.bin"

    path = File.join(File.dirname(__FILE__), "../../log/keep.bin")

    FileUtils.touch path

    sleep 1

    assert File.exists?(path)

    File.delete path
  end
end

