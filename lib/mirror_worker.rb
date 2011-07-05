
require "singleton"
require "net/sftp"
require "thread"
require "lib/error_handler"

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
    # If an optional block is given, the block is called when the workers are stopped.
    #
    #   MirrorWorker.instance.stop_all! do
    #     # the workers are stopped
    #   end
    #
    # or
    #
    #   MirrorWorker.instance.stop_all!
    #   
    #   # the workers are stopped
    
    def self.stop_all!
      # All workers share the same mutex. Therefore we can shutdown all at once

      @@mutex.synchronize do
        @thread.exit if @thread

        yield if block_given?
      end

      true
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
              case task.command
                when "mkdir"
                  @mirror.mkdir task.path
                when "rmdir"
                  @mirror.rmdir task.path
                when "delete"
                  @mirror.delete task.path
                when "write_to"
                  @mirror.write_to(task.path, File.read(File.join(PROXYFS_ROOT, "tmp/log", task.file)))
              end

              task.done
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

