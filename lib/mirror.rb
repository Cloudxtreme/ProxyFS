
require "net/sftp"
require "timeout"
require "stringio"
require "config/database"
require "lib/rand32"

module Net
  module SFTP
    # Useful extensions to <tt>Net::SFTP::Session</tt>.

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
    end
  end
end

module ProxyFS
  # Represents a remote +Mirror+ and provides the relevant remote file system operations.
  # Uses ActiveRecord for persistency.
  #
  #   mirror = Mirror.create :hostname => "example.com", :username => "username", :base_path => "/path/to/destination"
  #   mirror.mkdir "/test"
  #   mirror.upload("/path/to/file", "/test/test.txt")
  #   # ...
  #
  # If unsuccessfull, the remote operations raise exceptions.
  # The exception is one of <tt>Timeout::Error</tt>, <tt>Net::SFTP::StatusException</tt> or <tt>Errno::...</tt>

  class Mirror < ActiveRecord::Base
    validates_presence_of :hostname, :username, :base_path

    validates_uniqueness_of :hostname

    has_many :tasks, :order => :id, :dependent => :destroy

    @@timeout = 5

    # Returns true if a file or directory exists at +path+ on the remote host.

    def exists?(path)
      Timeout::timeout(@@timeout) do
        connect do |sftp|
          return sftp.exists? File.join(base_path, path)
        end
      end
    end

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

    # Uploads the file at +file+ to location +path+ on the remote host.

    def upload(file, path)
      # assume a 1K/s connection min

      Timeout::timeout([ File.size(file) / 1024.0, @@timeout ].max) do 
        connect do |sftp|
          temp_file = File.join(base_path, File.dirname(path), ".#{File.basename path}.#{ProxyFS.rand32}")

          sftp.upload!(file, temp_file)

          sftp.mv!(temp_file, File.join(base_path, path))
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

