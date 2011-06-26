
require File.dirname(__FILE__) + "/proxyfs/try"

module ProxyFS
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
      transaction = Transaction.new

      transaction.remote do |mirror|
        mirror.write_to(path, str)
      end

      transaction.local do
        Try.to(msg("write_to #{str.size} bytes", path)) do
          open(File.join(@base, path), "w") do |stream|
            stream.write str
          end
        end
      end

      transaction.rewind do |mirror|
        mirror.delete path
      end

      transaction.run
    end

    def can_delete?(path)
      true
    end

    def delete(path)
      transaction = Transaction.new

      transaction.remote do |mirror|
        mirror.delete path
      end

      transaction.local do
        Try.to(msg("delete", path)) do
          File.delete File.join(@base, path)
        end
      end

      transaction.rewind do |mirror|
        mirror.write_to(path, File.read(File.join(@base, path)))
      end

      transaction.run
    end

    def can_mkdir?(path)
      true
    end

    def mkdir(path)
      transaction = Transaction.new

      transaction.remote do |mirror|
        mirror.mkdir path
      end

      transaction.local do 
        Try.to(msg("mkdir", path)) do
          Dir.mkdir File.join(@base, path)
        end
      end

      transaction.rewind do |mirror|
        mirror.rmdir path
      end

      transaction.run
    end

    def can_rmdir?(path)
      true
    end

    def rmdir(path)
      transaction = Transaction.new

      transaction.remote do |mirror|
        mirror.rmdir path
      end

      transaction.local do 
        Try.to(msg("rmdir", path)) do
          Dir.rmdir File.join(@base, path)
        end
      end

      transaction.rewind do |mirror|
        mirror.mkdir path
      end

      transaction.run
    end

    def touch(path)
      # nothing, yet
    end

    private

    def msg(method, path)
      "local: #{method} #{File.join(@base, path)}"
    end
  end
end
