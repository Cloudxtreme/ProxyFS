
require "singleton"
require "thread"
require "config/logger"
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

    # Creates a new replication +Task+ to write the contents of +file+ to +path+ on all remote mirrors.

    def upload(file, path, &block)
      wrapper = lambda do
        block.call
      end

      replicate(wrapper, :command => "upload", :path => path, :file => file)
    end

    # Starts a +MirrorWorker+ for each +Mirror+.

    def replicate!
      @workers.each { |worker| worker.work! }
    end

    # Stops the creation of replication tasks gracefully.
    #
    #   Mirrors.instance.stop! do
    #     # creation of replication tasks stopped
    #   end

    def stop!
      PathMutex.stop! { yield }
    end

    private

    # Creates a replication +Task+ defined by +attributes+ (i.e. a ActiveRecord attributes hash
    # for the +Task+ model) for each remote +Mirror+. Assumes that a block is provided, that is
    # responsible to execute the operation on the local mirror as well (i.e. the local filesystem).
    # If the block raises an exception, the created tasks are deleted again using a +rollback+
    # operation of the database backend. Therefore, if the local operation fails, the operation
    # won't be replicated to the remote mirrors.

    def replicate(block, attributes)
      tasks = PathMutex.lock(attributes[:path]) do
        Task.transaction do
          # create a task for each mirror

          result = @mirrors.collect { |mirror| mirror.tasks.create attributes }

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

      if tasks
        @workers.each_with_index do |worker, i|
          worker.push tasks[i]
        end
      end
    end
  end
end

