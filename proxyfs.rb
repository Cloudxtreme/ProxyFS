
require "fusefs"
require "yaml"

class ProxyFS
  def initialize(base)
    @base = base
  end

  def contents(path)
    Dir.entries File.join(@base, path)
  end

  def file?(path)
    File.file? File.join(@base, path)
  end

  def directory?(path)
    File.directory? File.join(@base, path)
  end

  def read_file(path)
    File.read File.join(@base, path)
  end

  def executeable?(path)
    File.executeable? File.join(@base, path)
  end

  def size(path)
    File.size File.join(@base, path)
  end

  def can_write?(path)
    true
  end

  def write_to(path, str)
    # nothing
  end

  def can_delete?(path)
    true
  end

  def delete(path)
    # nothing
  end

  def can_mkdir?(path)
    true
  end

  def mkdir(path)
    # nothing
  end

  def can_rmdir?(path)
    true
  end

  def rmdir(path)
    # nothing
  end

  def touch(path)
    # nothing
  end
end

if ARGV.empty?
  puts "usage: [config file]"
  exit
end

config = YAML.load File.read(ARGV.shift)

mirror = ProxyFS.new config["local_path"]
FuseFS.set_root mirror
FuseFS.mount_under config["mount_point"]
FuseFS.run

