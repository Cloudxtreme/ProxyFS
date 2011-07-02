
require "test/lib/test_case"
require "test/units/fixtures"
require "lib/mirror"

class MirrorTest < ProxyFS::TestCase
  def setup
    setup_fixtures
  end

  def test_validates_presence_of_hostname
    mirror = ProxyFS::Mirror.create

    assert_equal("can't be blank", mirror.errors.on(:username))
  end

  def test_validates_presence_of_username
    mirror = ProxyFS::Mirror.create

    assert_equal("can't be blank", mirror.errors.on(:username))
  end

  def test_validates_presence_of_base_path
    mirror = ProxyFS::Mirror.create

    assert_equal("can't be blank", mirror.errors.on(:base_path))
  end

  def test_validates_uniqueness_of_hostname
    mirror = ProxyFS::Mirror.create :hostname => "127.0.0.1"

    assert_equal("has already been taken", mirror.errors.on(:hostname))
  end

  def test_tasks_order
    task = fixture(:mirror).tasks.create :command => "mkdir", :path => "/test"

    assert_equal [ fixture(:task), task ], fixture(:mirror).tasks
  end

  def test_destroy_tasks
    assert_difference("ProxyFS::Mirror.count", -1) do
      assert_difference("ProxyFS::Task.count", -1) do
        @fixtures[:mirror].destroy
      end
    end
  end

  def test_mkdir
    assert !File.directory?("/home/test/test")

    fixture(:mirror).mkdir "/test"

    assert File.directory?("/home/test/test")

    fixture(:mirror).rmdir "/test"
  end

  def test_rmdir
    fixture(:mirror).mkdir "/test"

    assert File.directory?("/home/test/test")

    fixture(:mirror).rmdir "/test"

    assert !File.directory?("/home/test/test")
  end

  def test_write_to
    assert !File.exists?("/home/test/test.txt")

    fixture(:mirror).write_to("/test.txt", "test")

    assert_equal("test", File.read("/home/test/test.txt"))

    fixture(:mirror).delete "/test.txt"
  end

  def test_delete
    fixture(:mirror).write_to("/test.txt", "test")

    assert File.exists?("/home/test/test.txt")

    fixture(:mirror).delete "/test.txt"

    assert !File.exists?("/home/test/test.txt")
  end
end

