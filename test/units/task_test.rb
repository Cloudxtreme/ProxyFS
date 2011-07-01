
require "test/lib/test_case"
require "test/units/fixtures"
require "lib/task"

class TaskTest < ProxyFS::TestCase
  def setup
    setup_fixtures
  end

  def test_validates_presence_of_command
    task = ProxyFS::Task.create

    assert_equal("can't be blank", task.errors.on(:command))
  end

  def test_validates_presence_of_path
    task = ProxyFS::Task.create

    assert_equal("can't be blank", task.errors.on(:path))
  end

  def test_validates_presence_of_mirror
    task = ProxyFS::Task.create

    assert_equal("can't be blank", task.errors.on(:mirror))
  end

  def test_belongs_to_mirror
    assert_equal(fixture(:mirror), fixture(:task).mirror)
  end

  def test_done
    assert_difference("Task.count", -1) do
      assert_difference("LOGGER.size") do
        fixture(:task).done
      end
    end
  end
end

