
require File.join(File.dirname(__FILE__), "task")
require File.join(File.dirname(__FILE__), "worker")
require File.join(File.dirname(__FILE__), "rand32")
require File.join(File.dirname(__FILE__), "logger")
require "digest"
require "fileutils"

class ProxyFS
  def initialize(base)
    @base = base

    @mirrors = Mirror.all
  end

  def contents(path)
    LOGGER.info "contents #{path}"

    Dir.entries File.join(@base, path)
  end

  def file?(path)
    LOGGER.info "file? #{path}"

    File.file? File.join(@base, path)
  end

  def directory?(path)
    LOGGER.info "directory? #{path}"

    File.directory? File.join(@base, path)
  end

  def read_file(path)
    LOGGER.info "read_file #{path}"

    File.read File.join(@base, path)
  end

  def executeable?(path)
    LOGGER.info "executeable? #{path}"

    File.executeable? File.join(@base, path)
  end

  def size(path)
    LOGGER.info "size #{path}"

    File.size File.join(@base, path)
  end

  def can_write?(path)
    LOGGER.info "can_write? #{path}"

    true
  end

  def write_to(path, str)
    LOGGER.info "write_to #{path}"

    # don't let the garbage collector run, while write_to is running.
    # we write to a temporary file (i.e. produce garbage), but the task is added later, because we use a transaction.
    # therefore, the garbage collector would think that the newly created temporary file is garbage and would delete it as soon as it runs.

    tasks = Worker.instance.garbage.synchronize do
      Task.transaction do
        file = "#{File.basename path}.#{rand32}"

        result = @mirrors.collect { |mirror| mirror.tasks.create! :command => "write_to", :path => path, :file => file }

        begin
          open(File.join(File.dirname(__FILE__), "../log", file), "w") do |stream|
            stream.write str
          end

          # write local file to temporary file first to provide more atomicity

          temp_file = File.join(@base, File.dirname(path), ".#{File.basename path}.#{rand32}")

          open(temp_file, "w") do |stream|
            stream.write str
          end

          FileUtils.mv(temp_file, File.join(@base, path))
        rescue Exception
          raise ActiveRecord::Rollback
        end

        result
      end
    end

    Worker.instance.add(tasks) if tasks
  end

  def can_delete?(path)
    LOGGER.info "can_delete? #{path}"

    true
  end

  def delete(path)
    LOGGER.info "delete #{path}"

    tasks = Task.transaction do
      result = @mirrors.collect { |mirror| mirror.tasks.create! :command => "delete", :path => path }

      begin
        File.delete File.join(@base, path)
      rescue Exception
        raise ActiveRecord::Rollback
      end

      result
    end

    Worker.instance.add(tasks) if tasks
  end

  def can_mkdir?(path)
    LOGGER.info "can_mkdir? #{path}"

    true
  end

  def mkdir(path)
    LOGGER.info "mkdir #{path}"

    tasks = Task.transaction do
      result = @mirrors.collect { |mirror| mirror.tasks.create! :command => "mkdir", :path => path }

      begin
        Dir.mkdir File.join(@base, path)
      rescue Exception
        raise ActiveRecord::Rollback
      end

      result
    end

    Worker.instance.add(tasks) if tasks
  end

  def can_rmdir?(path)
    LOGGER.info "can_rmdir? #{path}"

    true
  end

  def rmdir(path)
    LOGGER.info "rmdir #{path}"

    tasks = Task.transaction do
      result = @mirrors.collect{ |mirror| mirror.tasks.create! :command => "rmdir", :path => path }

      begin
        Dir.rmdir File.join(@base, path)
      rescue Exception
        raise ActiveRecord::Rollback
      end

      result
    end

    Worker.instance.add(tasks) if tasks
  end

  def touch(path)
    # nothing, yet
  end
end
