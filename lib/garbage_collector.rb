
require "thread"
require "singleton"
require "lib/task"

module ProxyFS
  # The +GarbageCollector+ deletes temporarily created log files.
  # Includes Singleton to assure that only one +GarbageCollector+ is running.
  #
  #   GarbageCollector.instance.collect!

  class GarbageCollector
    include Singleton

    @@timeout = 300

    # Creates a new +GarbageCollector+ object.

    def initialize
      @mutex = Mutex.new
    end

    # +synchronize+ allows to pause the +GarbageCollector+ during the execution of the block.
    #
    #   GarbageCollector.instance.synchronize do
    #     # the garbage collector won't run here
    #   end
    #
    # Can be used to pause the +GarbageCollector+, when temporary replication files and log entries are created.

    def synchronize
      @mutex.synchronize do
        yield
      end
    end

    # Stops the execution of the +GarbageCollector+ thread.
    # If a block is given, the block will be called, wenn the thread is terminted.
    #
    #   GarbageCollector.instance.stop! do
    #     # the garbage collector has terminted
    #   end
    #
    # or
    #
    #   GarbageCollector.instance.stop!
    #
    #   # the garbage collector has terminated

    def stop!
      synchronize do
        @thread.exit if @thread

        yield if block_given?
      end

      true
    end

    # Starts the +GarbageCollector+ thread.
    # The thread continously checks the log directory for temporary replication files without log entry reference.
    # Replication files without reference will be deleted, because they have been replicated to all mirrors and are no longer required.

    def collect!
      @thread = Thread.new do
        log_path = File.join(File.dirname(__FILE__), "../tmp/log")

        loop do
          synchronize do
            dir = Dir.entries log_path

            files = Task.all.collect(&:file).to_set

            dir.each do |file|
              full_path = File.join(log_path, file)

              File.delete(full_path) if file !~ /^\./ && !files.include?(file)
            end
          end

          sleep @@timeout
        end
      end
    end
  end
end

