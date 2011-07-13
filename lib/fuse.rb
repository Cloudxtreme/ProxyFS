
require "lib/mirrors"

module ProxyFS
  # Implements the FuseFS interface and all operations on the local directory (local mirror).
  # Uses FuseFS +raw+ methods (+raw_open+, +raw_read+, +raw_write+, +raw_close+),
  # because +write_to+ is buggy when append mode is used.
  # Check FuseFS <tt>API.txt</tt> for additional details.

  class Fuse
    # Creates a new Fuse object acting as a proxy for a local mirror directory at +base+.

    def initialize(base)
      @base = base

      @mirrors = Mirrors.instance

      @files = {}
    end

    # Lists the contents of +path+ on the local mirror.

    def contents(path)
      LOGGER.info "contents #{path}"

      Dir.entries File.join(@base, path)
    end

    # Returns +true+ if the file at +path+ on the local mirror exists and is a regular file.

    def file?(path)
      LOGGER.info "file? #{path}"

      File.file?(File.join(@base, path))
    end

    # Returns +true+ if the directory at +path+ on the local mirror exists and is a directory.

    def directory?(path)
      LOGGER.info "directory? #{path}"

      File.directory? File.join(@base, path)
    end

    # Returns +true+ if the file at +path+ on the local mirror exists and is executable.

    def executable?(path)
      LOGGER.info "executable? #{path}"

      File.executable?(File.join(@base, path))
    end

    # Returns the size of the file at +path+ on the local mirror in bytes.

    def size(path)
      LOGGER.info "size #{path}"

      File.size File.join(@base, path)
    end

    # Always returns +true+. Permissions have to be enforced on a lower layer.

    def can_write?(path)
      LOGGER.info "can_write? #{path}"

      true
    end

    # Opens the file for +path+ if the file is not already opened.

    def raw_open(path, mode)
      LOGGER.info "raw_open #{path} #{mode}"

      if mode == "r" || mode == "w" || mode == "w+"
        @files[path] = open(File.join(@base, path), mode)
      else
        @files[path] = open(File.join(@base, path), "a+")
      end
    end

    # Reads +sz+ bytes of the file for +path+ starting at offset +off+.

    def raw_read(path, off, sz)
      LOGGER.info "raw_read #{path} #{off} #{sz}"

      @files[path].seek(off, IO::SEEK_SET)

      @files[path].read sz
    end

    # Writes +sz+ bytes of +buf+ to the file for +path+ starting at offset +off+.

    def raw_write(path, off, sz, buf)
      LOGGER.info "raw_write #{path} #{off} #{sz}"

      if @files[path]
        @files[path].seek(off, IO::SEEK_SET)

        @files[path].write(buf[0, sz])
      end
    end

    # Closes the file for +path+.

    def raw_close(path)
      LOGGER.info "raw_close #{path}"

      if @files[path]
        @mirrors.upload(File.join(@base, path), path) do
          @files[path].close
        end
      else
        LOGGER.error "closing non existent file handle"
      end
    end

    # Writes the contents of +str+ to a file at +path+.
    # Used by Fuse for +mv+.

    def write_to(path, str)
      LOGGER.info "write_to #{path}"

      full_path = File.join(@base, path)

      @mirrors.upload(path) do
        open(full_path, "w") { |stream| stream.write str }
      end
    end

    # Returns the contents of the file at +path+.

    def read_file(path)
      LOGGER.info "read_file #{path}"

      File.read File.join(@base, path)
    end

    # Always returns +true+. Permissions have to be enforced on a lower layer.

    def can_delete?(path)
      LOGGER.info "can_delete? #{path}"

      true
    end

    # Deletes the file at +path+ on all mirrors.

    def delete(path)
      LOGGER.info "delete #{path}"

      @mirrors.delete(path) do
        File.delete File.join(@base, path)
      end
    end

    # Always returns +true+. Permissions have to be enforced on a lower layer.

    def can_mkdir?(path)
      LOGGER.info "can_mkdir? #{path}"

      true
    end

    # Creates a new directory at +path+ on all mirrors.

    def mkdir(path)
      LOGGER.info "mkdir #{path}"

      @mirrors.mkdir(path) do
        Dir.mkdir File.join(@base, path)
      end
    end

    # Always returns +true+. Permissions have to be enforced on a lower layer.

    def can_rmdir?(path)
      LOGGER.info "can_rmdir? #{path}"

      true
    end

    # Deletes a directory at +path+ on all mirrors.

    def rmdir(path)
      LOGGER.info "rmdir #{path}"

      @mirrors.rmdir(path) do
        Dir.rmdir File.join(@base, path)
      end
    end

    # +touch+ is not yet implemented.

    def touch(path)
      LOGGER.info "touch #{path}"

      # nothing, yet
    end
  end
end

