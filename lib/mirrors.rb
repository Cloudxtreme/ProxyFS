
require "singleton"
require "thread"
require "config/logger"
require "lib/garbage_collector"
require "lib/mirror_worker"
require "lib/mirror"
require "lib/task"

module ProxyFS
  # Manages the collection of remote mirrors to appear like if we have to communicate with a single mirror.
  # E.g., to create a replication +Task+ (mkdir) for every mirror, you have to call only once:
  #
  #   Mirrors.instance.mkdir("/new/directory") do
  #     # create directory on local mirror here (i.e. the local filesystem)
  #   end

  class Mirrors
    include Singleton

    # Creates a new +Mirrors+ object.

    def initialize
      @mirrors = Mirror.all

      @workers = @mirrors.collect { |mirror| MirrorWorker.new mirror }

      @mutex = Mutex.new
    end

    # Creates a new replication +Task+ to delete the file at +path+ on all remote mirrors.

    def delete(path, &block)
      replicate(block, :command => "delete", :path => path)
    end

    # Creates a new replication +Task+ to create a new directory at +path+ on all remote mirrors.

    def mkdir(path, &block)
      replicate(block, :command => "mkdir", :path => path)
    end

    # Creates a new replication +Task+ to delete a directory at +path+ on all remote mirrors.

    def rmdir(path, &block)
      replicate(block, :command => "rmdir", :path => path)
    end

    # Creates a new replication +Task+ to write the contents of +str+ to all remote mirrors.
    # Additionally creates a temporary replication file to store +str+ until it has been replicated.
    # The +GarbageCollector+ will delete it afterwards.

    def write_to(path, str, &block)
      file = "#{File.basename path}.#{ProxyFS.rand32}"
      
      wrapper = lambda do
        open(File.join(File.dirname(__FILE__), "../tmp/log", file), "w") { |stream| stream.write str }

        block.call
      end

      replicate(wrapper, :command => "write_to", :path => path, :file => file)
    end

    # Starts a +MirrorWorker+ for each +Mirror+.

    def replicate!
      @workers.each do |worker|
        worker.work!
      end
    end

    # Stops the creation of replication tasks gracefully.
    #
    #   Mirrors.instance.stop! do
    #     # creation of replication tasks stopped
    #   end

    def stop!
      # starts a new thread to prevent from ThreadErrors raised by the mutex

      Thread.new do
        @mutex.synchronize do
          yield
        end
      end

      true
    end

    private

    # Creates a replication +Task+ defined by +attributes+ (i.e. a ActiveRecord attributes hash
    # for the +Task+ model) for each remote +Mirror+. Assumes that a block is provided, that is
    # responsible to execute the operation on the local mirror as well (i.e. the local filesystem).
    # If the block raises an exception, the created tasks are deleted again using a +rollback+
    # operation of the database backend. Therefore, if the local operation fails, the operation
    # won't be replicated to the remote mirrors. In addition, the block is responsible for creating
    # an optional temporary replication file that is used for +write_to+. Therefore, +replicate+
    # is synchronized with the  +GarbageCollector+ to assure that these replication files are not
    # deleted until the database transaction is finished.

    def replicate(block, attributes)
      tasks = GarbageCollector.instance.synchronize do
        @mutex.synchronize do
          Task.transaction do
            # create a +Task+ for each +Mirror+

            result = @mirrors.collect { |mirror| mirror.tasks.create! attributes }

            # call the block that is responsible for the local filesystem operations

            begin
              block.call

              LOGGER.info "local: #{attributes[:command]} #{attributes[:path]}: done"
            rescue Exception
              # the local operation failed, now roll back to remove the already created tasks

              raise ActiveRecord::Rollback
            end

            result
          end
        end
      end

      if tasks
        @workers.each_with_index do |worker, i|
          worker.push tasks[i]
        end
      end
    end
  end
end

