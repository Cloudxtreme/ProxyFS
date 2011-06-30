
require "singleton"
require "config/logger"
require "lib/garbage_collector"
require "lib/mirror_worker"
require "lib/mirror"
require "lib/task"

module ProxyFS
  class Mirrors
    include Singleton

    def initialize
      @mirrors = Mirror.all

      @workers = @mirrors.collect { |mirror| MirrorWorker.new mirror }
    end

    def delete(path, &block)
      replicate({ :command => "delete", :path => path }, block)
    end

    def mkdir(path, &block)
      replicate({ :command => "mkdir", :path => path }, block)
    end

    def rmdir(path, &block)
      replicate({ :command => "rmdir", :path => path }, block)
    end

    def write_to(path, file, &block)
      replicate({ :command => "write_to", :path => path, :file => file }, block)
    end

    def replicate!
      @workers.each do |worker|
        worker.work!
      end
    end

    private

    def replicate(attributes, block)
      tasks = GarbageCollector.instance.synchronize do
        Task.transaction do
          result = @mirrors.collect { |mirror| mirror.tasks.create! attributes }

          begin
            block.call

            LOGGER.info "local: #{attributes[:command]} #{attributes[:path]}: done"
          rescue Exception
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

