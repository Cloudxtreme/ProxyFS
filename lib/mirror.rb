
require "net/sftp"
require "timeout"
require "stringio"
require "config/database"
require "lib/rand32"

module Net
  module SFTP
    # Useful extensions to Net::SFTP::Session.

    class Session
      # Returns true if a file or directory exists at +path+ on the remote host.

      def exists?(path)
        begin
          stat! path

          return true
        rescue StatusException => e
          raise e if e.code != Constants::StatusCodes::FX_NO_SUCH_FILE
        end

        false
      end

      # Moves a file (only files) from +source+ to +destination+ on the remote host to provide
      # more atomicity. Unfortunately, the operation is not yet completly atomic.
      # If the file at +destination+ already exists, it is deleted first.

      def mv!(source, destination)
        remove!(destination) if exists?(destination)

        rename!(source, destination)
      end

      # Uploads the contents of +str+ to file at +path+ on the remote host.

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
  # Represents a remote +Mirror+ and provides the relevant remote file system operations.
  # Uses ActiveRecord for persistency.
  #
  #   mirror = Mirror.create :hostname => "example.com", :username => "username", :base_path => "/path/to/destination"
  #   mirror.mkdir "/test"
  #   mirror.write_to("/test/test.txt", "test")
  #   # ...
  #
  # If unsuccessfull, the remote operations raise exceptions.
  # The exception is one of +Timeout::Error+, +Net::SFTP::StatusException+ or +Errno::...+

  class Mirror < ActiveRecord::Base
    validates_presence_of :hostname, :username, :base_path

    validates_uniqueness_of :hostname

    has_many :tasks, :order => :id, :dependent => :destroy

    @@timeout = 5

    # Creates a new directory at +path+ on the remote host.

    def mkdir(path)
      Timeout::timeout(@@timeout) do
        connect do |sftp|
          sftp.mkdir! File.join(base_path, path)
        end
      end
    end

    # Deletes the directory at +path+ on the remote host. 

    def rmdir(path)
      Timeout::timeout(@@timeout) do
        connect do |sftp|
          sftp.rmdir! File.join(base_path, path)
        end
      end
    end

    # Writes the contents of +str+ to +path+ on the remote host.

    def write_to(path, str)
      Timeout::timeout([ str.size / 1024.0, @@timeout ].max) do 
        connect do |sftp|
          # assume a 1K/s connection min

          tempfile = File.join(base_path, File.dirname(path), ".#{File.basename path}.#{ProxyFS.rand32}")

          sftp.upload_data!(tempfile, str)

          sftp.mv!(tempfile, File.join(base_path, path))
        end
      end
    end

    # Deletes the file at +path+ on the remote host.

    def delete(path)
      Timeout::timeout(@@timeout) do
        connect do |sftp|
          sftp.remove! File.join(base_path, path)
        end
      end
    end

    private

    # Connects to the remote host. Assumes that a block is provided.
    #
    #   connect do |sftp|
    #     # connected
    #   end

    def connect
      Net::SFTP.start(hostname, username) do |sftp| 
        yield sftp
      end
    end
  end
end

