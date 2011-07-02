
require "test/lib/test_case"
require "lib/mirrors"

module ProxyFS
  class Mirrors
    attr_accessor :workers
  end
end

class TestWorker < Array
  # interface of array is sufficient
end

class MirrorsTest < ProxyFS::TestCase
  def setup
    @mirrors = ProxyFS::Mirrors.instance

    @worker = TestWorker.new

    @mirrors.workers = [ @worker ]
  end

  def test_mkdir
    assert_difference("Task.count") do
      assert_difference("LOGGER.size") do
        assert_difference("@worker.size") do
          @mirrors.mkdir("/test") do
            # nothing
          end
        end
      end
    end
  end

  def test_rmdir
    assert_difference("Task.count") do
      assert_difference("LOGGER.size") do
        assert_difference("@worker.size") do
          @mirrors.rmdir "/test" do
            # nothing
          end
        end
      end
    end
  end

  def test_write_to
    assert_difference("Task.count") do
      assert_difference("@worker.size") do
        assert_difference("LOGGER.size") do
          @mirrors.write_to("/test.txt", "test") do
            # nothing
          end
        end
      end
    end
  end

  def test_delete
    assert_difference("Task.count") do
      assert_difference("@worker.size") do
        assert_difference("LOGGER.size") do
          @mirrors.delete "/test.txt" do
            # nothing
          end
        end
      end
    end
  end

  def test_fail
    assert_no_difference("Task.count") do
      assert_no_difference("@worker.size") do
        assert_no_difference("LOGGER.size") do
          @mirrors.mkdir("/test") do
            raise "fail"
          end
        end
      end
    end
  end

  def test_stop!
    @mirrors.stop! { assert true }
  end
end

