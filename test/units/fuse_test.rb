
require "test/lib/test_case"
require "lib/fuse"

class TestMirrors
  def mkdir(path)
    yield
  end

  def delete(path)
    yield
  end

  def write_to(path, str)
    yield
  end

  def rmdir(path)
    yield
  end
end

module ProxyFS
  class Fuse
    attr_accessor :mirrors
  end
end

class FuseTest < ProxyFS::TestCase
  def setup
    super

    @path = File.join(PROXYFS_ROOT, "test/mnt")

    @fuse = ProxyFS::Fuse.new @path

    @fuse.mirrors = TestMirrors.new
  end

  def test_contents
    assert_equal([ ".", "..", "test.txt", "test.bin", "test" ].sort, @fuse.contents("/").sort)
  end

  def test_file?
    assert @fuse.file?("/test.txt")
  end

  def test_directory?
    assert @fuse.directory?("/test")
  end

  def test_executable?
    assert @fuse.executable?("/test.bin")
  end

  def test_size
    assert_equal(4, @fuse.size("/test.txt"))
  end

  def test_can_write?
    assert @fuse.can_write?("/")
  end

  def test_can_delete?
    assert @fuse.can_delete?("/test.txt")
  end

  def test_can_mkdir?
    assert @fuse.can_mkdir?("/")
  end

  def test_can_rmdir?
    assert @fuse.can_rmdir?("/test")
  end

  def test_raw_open
    assert @fuse.raw_open("/test.txt", "w")

    assert !@fuse.raw_open("/missing.txt", "w")
  end

  def test_raw_read
    assert_equal("es", @fuse.raw_read("/test.txt", 1, 2))
  end

  def test_raw_write
    temp_file = File.join(PROXYFS_ROOT, "tmp/local", "f012f0eb338e56f45c5446b6bd9899cdc526c003")

    assert !File.exists?(temp_file)

    assert_equal(2, @fuse.raw_write("/new.txt", 0, 2, "new"))

    assert File.exists?(temp_file)

    File.delete temp_file
  end

  def test_raw_close
    temp_file = File.join(PROXYFS_ROOT, "tmp/local", "f012f0eb338e56f45c5446b6bd9899cdc526c003")

    assert !File.exists?(File.join(@path, "new.txt"))

    open(temp_file, "w") { |stream| stream.write "new" }

    @fuse.raw_close "/new.txt"

    assert_equal("new", File.read(File.join(@path, "new.txt")))

    assert !File.exists?(temp_file)

    File.delete File.join(@path, "new.txt")
  end

  def test_mkdir
    assert !File.exists?(File.join(@path, "tmp"))

    @fuse.mkdir "/tmp"

    assert File.directory?(File.join(@path, "tmp"))

    Dir.rmdir File.join(@path, "tmp")
  end

  def test_rmdir
    Dir.mkdir File.join(@path, "tmp")

    assert File.directory?(File.join(@path, "tmp"))

    @fuse.rmdir "/tmp"

    assert !File.exists?(File.join(@path, "tmp"))
  end

  def test_delete
    open(File.join(@path, "tmp.txt"), "w") { |stream| stream.write "tmp" }

    assert File.exists?(File.join(@path, "tmp.txt"))

    @fuse.delete("/tmp.txt")

    assert !File.exists?(File.join(@path, "tmp.txt"))
  end

  def test_touch
    # nothing, yet
  end
end

