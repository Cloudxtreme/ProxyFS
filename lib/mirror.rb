
require "net/sftp"
require "timeout"
require "stringio"
require File.join(File.dirname(__FILE__), "rand32")

# Extensions to Net::SFTP to provide additional functionality.

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
      # Unfortunately, the operation is not yet 'atomic' FIXME

      def mv!(source, destination)
        remove!(destination) if exists?(destination)

        rename!(source, destination)
      end

      # Upload data within +str+ to a file located at +path+.

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

class Mirror < ActiveRecord::Base
  validates_presence_of :hostname, :username, :path

  has_many :tasks, :order => :id

  @@timeout = 5

  def mkdir(path)
    Timeout::timeout(@@timeout) do
      connect do |sftp|
        sftp.mkdir! File.join(base_path, path)
      end
    end
  end

  def rmdir(path)
    Timeout::timeout(@@timeout) do
      connect do |sftp|
        sftp.rmdir! File.join(base_path, path)
      end
    end
  end

  # write_to generates a temporary file name, writes to the temporary file,
  # then moves the temporary file to its final destination.
  # Therefore, the possibilities of errors should be minimal, because
  # a possibly existing file is not accessed until the temporary file is moved.

  def write_to(path, str)
    Timeout::timeout([ str.size / 1024.0, @@timeout ].max) do 
      connect do |sftp|
        # assume a 1K/s connection min

        tempfile = File.join(base_path, File.dirname(path), ".#{File.basename path}.#{rand32}")

        sftp.upload_data!(tempfile, str)

        sftp.mv!(tempfile, File.join(base_path, path))
      end
    end
  end

  def delete(path)
    Timeout::timeout(@@timeout) do
      connect do |sftp|
        sftp.remove! File.join(base_path, path)
      end
    end
  end

  private

  def connect
    Net::SFTP.start(hostname, username) do |sftp|
      yield sftp
    end
  end
end

