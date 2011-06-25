
require "net/sftp"
require File.dirname(__FILE__) + "/try"

module ProxyFS
  class Mirror
    def initialize(user, host, path)
      @user = user
      @host = host
      @base = path

      @tries = { :times => 2, :wait => [ 1, 5 ] }
    end

    def mkdir(path)
      Try.to(msg("mkdir", path), @tries) do
        result = false

        connect do |sftp|
          sftp.mkdir! File.join(@base, path)

          result = true
        end

        result
      end
    end

    def rmdir(path)
      Try.to(msg("rmdir", path), @tries) do
        result = false

        connect do |sftp|
          sftp.rmdir! File.join(@base, path)

          result = true
        end

        result
      end
    end

    def write_to(path, str)
      Try.to(msg("write_to", path), @tries) do
        result = false

        connect do |sftp|
          sftp.file.open(File.join(@base, path), "w") do |stream|
            stream.write str
          end

          result = true
        end

        result
      end
    end

    def delete(path)
      Try.to(msg("delete", path), @tries) do
        result = false

        connect do |sftp|
          sftp.remove! File.join(@base, path)

          result = true
        end

        result
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

