
require File.join(File.dirname(__FILE__), "task")
require File.join(File.dirname(__FILE__), "worker")
require "digest"

class ProxyFS
  def initialize(base)
    @base = base

    @mirrors = Mirror.all
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
    Task.transaction do
      file = Digest::SHA1.hexdigest(str + rand.to_s)

      tasks = @mirrors.collect { |mirror| mirrors.tasks.create! :command => "write_to", :path => path, :file => file }

      open(File.join(File.dirname(__FILE__), "../log", file) do |stream|
        stream.write str
      end

      open(File.join(@base, path), "w") do |stream| # FIXME for atomicity write to temporary file first and mv afterwards
        stream.write str
      end

      Worker.instance.add tasks
    end
  end

  def can_delete?(path)
    true
  end

  def delete(path)
    Task.transaction do
      tasks = @mirrors.collect { |mirror| mirror.tasks.create! :command => "delete", :path => path }

      File.delete File.join(@base, path)

      Worker.instance.add tasks
    end
  end

  def can_mkdir?(path)
    true
  end

  def mkdir(path)
    Task.transaction do
      tasks = @mirrors.collect { |mirror| mirror.tasks.create! :command => "mkdir", :path => path }

      Dir.mkdir File.join(@base, path)

      Worker.instance.add tasks
    end
  end

  def can_rmdir?(path)
    true
  end

  def rmdir(path)
    Task.transaction do
      tasks = @mirrors.collect{ |mirror| mirror.tasks.create! :command => "rmdir", :path => path }

      Dir.rmdir File.join(@base, path)

      Worker.instance.add tasks
    end
  end

  def touch(path)
    # nothing, yet
  end

  private

  def msg(method, path)
    "local: #{method} #{File.join(@base, path)}"
  end
end
