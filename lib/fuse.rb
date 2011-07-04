
require "digest"
require "fileutils"
require "lib/mirrors"
require "lib/rand32"

module ProxyFS
  # Implements the FuseFS interface and all operations on the local directory (local mirror).
  # Check FuseFS API.txt for additional details.

  class Fuse
    # Creates a new Fuse object as a proxy for a local mirror directory at +base+.

    def initialize(base)
      @base = base

      @mirrors = Mirrors.instance
    end

    # Lists the contents of +path+ on the local mirror.

    def contents(path)
      Dir.entries File.join(@base, path)
    end

    # Returns true if the file at +path+ on the local mirror exists and is a regular file.

    def file?(path)
      File.file? File.join(@base, path)
    end

    # Returns true if the directory at +path+ on the local mirror exists and is a directory.

    def directory?(path)
      File.directory? File.join(@base, path)
    end

    # Returns the contents of the file at +path+ on the local mirror.

    def read_file(path)
      File.read File.join(@base, path)
    end

    # Returns true if the file at +path+ on the local mirror exists and is executable.

    def executable?(path)
      File.executable? File.join(@base, path)
    end

    # Returns the size of the file at +path+ on the local mirror in bytes.

    def size(path)
      File.size File.join(@base, path)
    end

    # Always returns true. Permissions have to be enforced on a lower layer.

    def can_write?(path)
      true
    end

    # Writes the contents of +str+ into the file at +path+ on all mirrors.
    # The contents are first written into a temporary file.
    # Afterwards the file is moved to its final destination.
    # This provides a bit more atomicity.

    def write_to(path, str)
      @mirrors.write_to(path, str) do
        temp_file = File.join(@base, File.dirname(path), ".#{File.basename path}.#{ProxyFS.rand32}")

        open(temp_file, "w") { |stream| stream.write str }

        FileUtils.mv(temp_file, File.join(@base, path))
      end
    end

    # Always returns true. Permissions have to be enforced on a lower layer.

    def can_delete?(path)
      true
    end

    # Deletes the file at +path+ on all mirrors.

    def delete(path)
      @mirrors.delete(path) do
        File.delete File.join(@base, path)
      end
    end

    # Always returns true. Permissions have to be enforced on a lower layer.

    def can_mkdir?(path)
      true
    end

    # Creates a new directory at +path+ on all mirrors.

    def mkdir(path)
      @mirrors.mkdir(path) do
        Dir.mkdir File.join(@base, path)
      end
    end

    # Always returns true. Permissions have to be enforced on a lower layer.

    def can_rmdir?(path)
      true
    end

    # Deletes a directory at +path+ on all mirrors.

    def rmdir(path)
      @mirrors.rmdir(path) do
        Dir.rmdir File.join(@base, path)
      end
    end

    # +touch+ is not yet implemented.

    def touch(path)
      # nothing, yet
    end
  end
end

