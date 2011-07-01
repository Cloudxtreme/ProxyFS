
require "thread"
require "singleton"
require "lib/task"

module ProxyFS
  class GarbageCollector
    include Singleton

    @@timeout = 300

    def initialize
      @mutex = Mutex.new
    end

    def synchronize
      @mutex.synchronize do
        yield
      end
    end

    def collect!
      Thread.new do
        log_path = File.join(File.dirname(__FILE__), "../log")

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

