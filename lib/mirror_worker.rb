
require "singleton"
require "net/sftp"
require "thread"
require "lib/error_handler"

module ProxyFS
  class MirrorWorker
    @@mutex = Mutex.new

    def initialize(mirror)
      @mirror = mirror

      @queue = Queue.new

      @mirror.tasks.each do |task|
        @queue.push task
      end
    end

    def push(task)
      @queue.push task
    end

    # All workers share the same mutex. Therefore we can shutdown all at once

    def self.stop_all
      @@mutex.synchronize do
        @thread.exit if @thread

        yield if block_given?
      end

      true
    end

    def work!
      @thread = Thread.new do
        loop do
          task = @queue.pop

          begin
            @@mutex.synchronize do
              case task.command
                when "mkdir"
                  @mirror.mkdir task.path
                when "rmdir"
                  @mirror.rmdir task.path
                when "delete"
                  @mirror.delete task.path
                when "write_to"
                  file = File.join(File.dirname(__FILE__), "../tmp/log", task.file)

                  @mirror.write_to(task.path, File.read(file))

                  File.delete file
              end

              task.done
            end
          rescue Exception => e
            ErrorHandler.new(@mirror, task).handle e

            retry
          end
        end
      end
    end
  end
end

