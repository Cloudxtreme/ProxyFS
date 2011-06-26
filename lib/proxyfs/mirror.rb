
require "net/sftp"
require "timeout"
require File.dirname(__FILE__) + "/try"
require File.dirname(__FILE__) + "/out_of_sync_exception"

module ProxyFS
  class Mirror
    def initialize(user, host, path, tries, timeout)
      @user = user
      @host = host
      @base = path

      @tries = tries
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

    def write_to(path, str)
      Try.to(msg("write_to", path), @tries) do
        connect do |sftp|
          # assume a 1K/s connection min

          Timeout::timeout([ str.size / 1024, @timeout ].max) do 
            sftp.file.open(File.join(@base, path), "w") do |stream|
              stream.write str
            end
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

    def connect
      Net::SFTP.start(@host, @user) do |sftp|
        yield sftp
      end
    end
  end
end

