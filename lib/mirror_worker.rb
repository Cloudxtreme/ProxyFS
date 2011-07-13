
require "singleton"
require "thread"
require "lib/error_handler"
require "lib/path_mutex"

module ProxyFS
  # Takes all tasks for a remote +Mirror+, and tries to execute them until successfully replicated.

  class MirrorWorker
    @@mutex = Mutex.new

    # Creates a new +MirrorWorker+ object.

    def initialize(mirror)
      @mirror = mirror

      @queue = Queue.new

      @mirror.tasks.each do |task|
        @queue.push task
      end
    end

    # Adds a +Task+ to the queue of open tasks for the +Mirror+.

    def push(task)
      @queue.push task
    end

    # Stops the workers for all mirrors at once.
    #
    #   MirrorWorker.instance.stop_all! do
    #     # the workers are stopped
    #   end
    
    def self.stop_all!
      # All workers share the same mutex. Therefore we can shutdown all at once

      Thread.new do
        @@mutex.synchronize do
          @thread.exit if @thread

          yield
        end
      end
    end

    # Creates a new thread to process the +Task+ queue.
    # Reads one +Task+ at a time from the queue and replicates the operation until success.
    # If an exception is raised while the operation is replicated, an +ErrorHandler+ will
    # be created and called. After the +ErrorHandler+ has finished, it will retry to
    # replicate the operation.

    def work!
      @thread = Thread.new do
        loop do
          task = @queue.pop

          error_handler = ErrorHandler.new(@mirror, task)

          begin
            @@mutex.synchronize do
              PathMutex.lock(task.path) do
                unless Task.any_newer?(task.path, task.created_at)
                  case task.command
                    when "mkdir"
                      @mirror.mkdir(task.path) if !@mirror.exists?(task.path)
                    when "rmdir"
                      @mirror.rmdir(task.path) if @mirror.exists?(task.path)
                    when "delete"
                      @mirror.delete(task.path) if @mirror.exists?(task.path)
                    when "upload"
                      @mirror.upload(task.file, task.path)
                  end
                end

                task.done
              end
            end
          rescue Exception => e
            error_handler.handle e

            retry
          end
        end
      end
    end
  end
end

