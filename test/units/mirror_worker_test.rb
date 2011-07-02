
require "test/lib/test_case"
require "test/units/fixtures"
require "lib/mirror_worker"
require "lib/task"
require "fileutils"

module ProxyFS
  class MirrorWorker
    attr_reader :queue
  end
end

class TestMirror
  attr_reader :commands
  attr_accessor :fail

  def initialize
    @fail = false

    @commands = []
  end

  def tasks
    []
  end

  def mkdir(path)
    raise "fail" if @fail

    @commands.push [ "mkdir", path ]
  end

  def rmdir(path)
    raise "fail" if @fail

    @commands.push [ "rmdir", path ]
  end

  def write_to(path, str)
    raise "fail" if @fail

    @commands.push [ "write_to", path, str ]
  end

  def delete(path)
    raise "fail" if @fail

    @commands.push [ "delete", path ]
  end
end

class MirrorWorkerTest < ProxyFS::TestCase
  def setup
    setup_fixtures

    @mirror = TestMirror.new

    @worker = ProxyFS::MirrorWorker.new @mirror

    @worker.work!
  end

  def teardown
    ProxyFS::MirrorWorker.stop_all!
  end

  def test_push
    @worker = ProxyFS::MirrorWorker.new fixture(:mirror)

    assert_difference("@worker.queue.size") do
      @worker.push ProxyFS::Task.new
    end
  end

  def test_mkdir
    assert_difference("@mirror.commands", [[ "mkdir", "/test" ]]) do
      @worker.push ProxyFS::Task.create(:command => "mkdir", :path => "/test")

      sleep 1
    end
  end

  def test_delete
    assert_difference("@mirror.commands", [[ "delete", "/test.txt" ]]) do
      @worker.push ProxyFS::Task.create(:command => "delete", :path => "/test.txt")

      sleep 1
    end
  end

  def test_rmdir
    assert_difference("@mirror.commands", [[ "rmdir", "/test" ]]) do
      @worker.push ProxyFS::Task.create(:command => "rmdir", :path => "/test")

      sleep 1
    end
  end

  def test_write_to
    assert_difference("@mirror.commands", [[ "write_to", "/test.txt", "test" ]]) do
      open(File.join(File.dirname(__FILE__), "../../tmp/log/test.bin"), "w") do |stream|
        stream.write "test"
      end

      @worker.push ProxyFS::Task.create(:command => "write_to", :path => "/test.txt", :file => "test.bin")

      sleep 1
    end
  end

  def test_fail
    @mirror.fail = true

    assert_no_difference("@mirror.commands") do
      @worker.push ProxyFS::Task.create(:command => "mkdir", :path => "/test")

      sleep 1
    end
  end

  def test_stop!
    assert ProxyFS::MirrorWorker.stop_all!
  end
end

