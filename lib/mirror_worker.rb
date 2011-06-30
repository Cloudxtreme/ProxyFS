
require "singleton"
require "net/sftp"
require "thread"
require File.expand_path File.join(File.dirname(__FILE__), "../config/logger")
require File.expand_path File.join(File.dirname(__FILE__), "error_handler")
require File.expand_path File.join(File.dirname(__FILE__), "mirror")
require File.expand_path File.join(File.dirname(__FILE__), "task")

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

    def work!
      Thread.new do
        loop do
          @@mutex.synchronize do
            task = @queue.pop

            begin
              case task.command
                when "mkdir"
                  @mirror.mkdir task.path
                when "rmdir"
                  @mirror.rmdir task.path
                when "delete"
                  @mirror.delete task.path
                when "write_to"
                  file = File.join(File.dirname(__FILE__), "../log", task.file)

                  @mirror.write_to(task.path, File.read(file))

                  File.delete file
              end

              task.done!
            rescue Exception => e
              ErrorHandler.new(@mirror, task).handle e

              retry
            end
          end
        end
      end
    end
  end
end

