
require "thread"
require "lib/mirrors"
require "lib/mirror_worker"

module ProxyFS
  # Shuts down ProxyFS services (+GarbageCollector+, +MirrorWorker+, +Mirrors+) gracefully.

  def self.exit!
    GarbageCollector.instance.stop!
    MirrorWorker.stop_all!

    Mirrors.instance.stop! { Kernel.exit }
  end
end

