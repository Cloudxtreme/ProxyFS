
require "net/sftp"
require "timeout"
require "stringio"
require "escape"
require File.dirname(__FILE__) + "/try"
require File.dirname(__FILE__) + "/out_of_sync_exception"

module Net
  module SFTP
    class Session
      # Check whether or not the file exists at +path+.

      def exists?(path)
        begin
          stat! path

          return true
        rescue StatusException => e
          raise e if e.code != Constants::StatusCodes::FX_NO_SUCH_FILE
        end

        false
      end

      # Rename a file. If +destination+ already exists, it will be deleted first.
      # Unfortunately, the operation is not yet atomic FIXME

      def mv!(source, destination)
        remove!(destination) if exists?(destination)

        rename!(source, destination)
      end

      def upload_data!(path, str)
        file.open(path, "w") do |stream|
          StringIO.open(str) do |string_io|
            stream.write string_io.read(1024) until string_io.eof?
          end
        end
      end
    end
  end
end

module ProxyFS
  class Mirror
    def initialize(user, host, path, times, wait, timeout)
      @user = user
      @host = host
      @base = path

      @tries = { :times => times, :wait => wait }
      @timeout = timeout
    end

    def mkdir(path)
      Try.to(msg("mkdir", path), @tries) do
        Timeout::timeout(@timeout) do
          connect do |sftp|
            sftp.mkdir! File.join(@base, path)
          end
        end

        true
      end
    end

    def rmdir(path)
      Try.to(msg("rmdir", path), @tries) do
        Timeout::timeout(@timeout) do
          connect do |sftp|
            sftp.rmdir! File.join(@base, path)
          end
        end

        true
      end
    end

    # write_to generates a temporary file name, writes to the temporary file,
    # then moves the temporary file to its final destination.
    # Therefore, the possibilities of errors should be minimal, because
    # a possibly existing file is not accessed until the temporary file is mooved.

    def write_to(path, str)
      Try.to(msg("write_to #{str.size} bytes", path), @tries) do
        connect do |sftp|
          # assume a 1K/s connection min

          Timeout::timeout([ str.size / 1024.0, @timeout ].max) do 
            tempfile = File.join(@base, tempfile_for(path))

            raise "temporary file already exists" if sftp.exists? tempfile

            sftp.upload_data!(tempfile, str)

            sftp.mv!(tempfile, File.join(@base, path))
          end
        end

        true
      end
    end

    def delete(path)
      Try.to(msg("delete", path), @tries) do
        Timeout::timeout(@timeout) do
          connect do |sftp|
            sftp.remove! File.join(@base, path)
          end
        end

        true
      end
    end

    private

    def msg(method, path)
      "#{@host}: #{method} #{File.join(@base, path)}"
    end

    def tempfile_for(path)
      chars = ("a" .. "z").to_a + ("A" .. "Z").to_a + ("0" .. "9").to_a

      File.join(File.dirname(path), ".#{File.basename path}.#{6.times.collect{ chars[rand chars.size] }.join}")
    end

    def connect
      Net::SFTP.start(@host, @user) do |sftp|
        yield sftp
      end
    end
  end
end

