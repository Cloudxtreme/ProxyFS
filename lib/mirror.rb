
require "net/sftp"
require "timeout"
require "stringio"
require File.expand_path File.join(File.dirname(__FILE__), "../config/database")
require File.expand_path File.join(File.dirname(__FILE__), "rand32")

module Net
  module SFTP
    class Session
      def exists?(path)
        begin
          stat! path

          return true
        rescue StatusException => e
          raise e if e.code != Constants::StatusCodes::FX_NO_SUCH_FILE
        end

        false
      end

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
  class Mirror < ActiveRecord::Base
    validates_presence_of :hostname, :username, :base_path

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

    def delete(path)
      Timeout::timeout(@@timeout) do
        connect do |sftp|
          sftp.remove! File.join(base_path, path)
        end
      end
    end

    private

    def connect
      Net::SFTP.start(hostname, username) { |sftp| yield sftp }
    end
  end
end

