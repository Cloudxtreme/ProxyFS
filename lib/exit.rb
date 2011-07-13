
require "thread"
require "lib/mirrors"
require "lib/mirror_worker"

module ProxyFS
  # Shuts down ProxyFS services (+MirrorWorker+, +Mirrors+) gracefully and then exits.

  def self.exit!
    MirrorWorker.stop_all! do
      Mirrors.instance.stop! do
        Kernel.exit
      end
    end
  end
end

