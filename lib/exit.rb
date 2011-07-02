
require "thread"
require "lib/mirrors"
require "lib/mirror_worker"

module ProxyFS
  def self.exit
    GarbageCollector.instance.stop do
      MirrorWorker.stop_all do
        Mirrors.instance.stop do
          Kernel.exit
        end
      end
    end
  end
end

