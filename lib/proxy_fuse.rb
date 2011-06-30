
require "digest"
require "fileutils"
require "lib/mirrors"
require "lib/rand32"

module ProxyFS
  class ProxyFuse
    def initialize(base)
      @base = base

      @mirrors = Mirrors.instance
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
      file = "#{File.basename path}.#{ProxyFS.rand32}"

      @mirrors.write_to(path, file) do
        open(File.join(File.dirname(__FILE__), "../log", file), "w") do |stream|
          stream.write str
        end

        # write local file to temporary file first to provide more atomicity

        temp_file = File.join(@base, File.dirname(path), ".#{File.basename path}.#{ProxyFS.rand32}")

        open(temp_file, "w") do |stream|
          stream.write str
        end

        FileUtils.mv(temp_file, File.join(@base, path))
      end
    end

    def can_delete?(path)
      true
    end

    def delete(path)
      @mirrors.delete(path) do
        File.delete File.join(@base, path)
      end
    end

    def can_mkdir?(path)
      true
    end

    def mkdir(path)
      @mirrors.mkdir(path) do
        Dir.mkdir File.join(@base, path)
      end
    end

    def can_rmdir?(path)
      true
    end

    def rmdir(path)
      @mirrors.rmdir(path) do
        Dir.rmdir File.join(@base, path)
      end
    end

    def touch(path)
      # nothing, yet
    end
  end
end

