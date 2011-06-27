
require File.join(File.dirname(__FILE__), "task")
require File.join(File.dirname(__FILE__), "worker")
require File.join(File.dirname(__FILE__), "rand32")
require "digest"
require "fileutils"

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
      file = "#{File.basename path}.#{rand32}"

      tasks = @mirrors.collect { |mirror| mirrors.tasks.create! :command => "write_to", :path => path, :file => file }

      open(File.join(File.dirname(__FILE__), "../log", file) do |stream|
        stream.write str
      end

      # write local file to temporary file first to provide more atomicity

      temp_file = File.join(@base, File.dirname(path), ".#{File.basename path}.#{rand32}")

      open(temp_file, "w") do |stream|
        stream.write str
      end

      FileUtils.mv(temp_file, path)

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
end
