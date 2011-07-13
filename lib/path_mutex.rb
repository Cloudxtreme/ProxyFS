
require "thread"

module ProxyFS
  # +PathMutex+ provides an easy to use file locking mechanism to guarantee
  # mutual exlusion when critical operations on files are executed.
  #
  #   PathMutex.lock("/path/to/file") do
  #     # e.g. delete file
  #   end

  class PathMutex
    @@mutexes = {}
    @@mutex = Mutex.new
    @@stop = nil

    # Causes +PathMutex+ to not accept any further locking and calls the given +block+ when done.

    def self.stop!(&block)
      Thread.new do
        @@mutex.synchronize do
          @@stop = block

          @@stop.call if @@mutexes.empty?
        end
      end
    end

    # Creates a mutex for +path+ if non exists, yet.
    # Afterwards, the mutex is locked and the given block is called.
    # At the end, the mutex is unlocked, and the mutex for +path+ is deleted to ensure that the mutex
    # will not stay in memory forever, i.e. can be cleaned up by the garbage collector.
    # Creation and deletion of the mutex is synchronized.

    def self.lock(path)
      mutex = nil

      @@mutex.lock

      # sleep forever if we want to stop

      if @@stop
        @@mutex.unlock

        sleep
      end

      @@mutexes[path] = { :mutex => Mutex.new, :count => 0 } unless @@mutexes[path]

      mutex = @@mutexes[path]

      mutex[:count] += 1

      @@mutex.unlock

      mutex[:mutex].lock
      
      yield
    ensure
      mutex[:mutex].unlock

      @@mutex.synchronize do
        mutex[:count] -= 1

        @@mutexes.delete(path) if mutex[:count].zero?

        # call stop block if we want to stop

        @@stop.call if @@stop && @@mutexes.empty?
      end
    end
  end
end

