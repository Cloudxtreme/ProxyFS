
require "singleton"
require "queue"

require File.join(File.dirname(__FILE__), "mirror")

class Worker
  include Singleton

  def initialize
    @mirrors = Mirror.all

    @queues = @mirrors.collect { Queue.new }
  end

  def add(tasks)
    @queues.each_with_index do |queue, i|
      queue.push tasks[i]
    end
  end

  def work!
    Thread.new do
      log_path = File.join(File.dirname(__FILE__), "../log")

      loop do
        files = Task.all.collect(&:file).to_set

        Dir.foreach(log_path) do |file|
          full_path = File.join(log_path, file)

          File.delete(full_path) if File.file?(full_path) && !files.include?(file)
        end

        sleep 300
      end
    end

    @mirrors.each_with_index do |mirror, i|
      Thread.new do
        queue = @queues[i]

        loop do
          task = queue.pop

          Task.transaction do
            task.destroy!

            loop do
              result = case task.command
                when "mkdir":
                  mirror.mkdir task.path
                when "rmdir":
                  mirror.rmdir task.path
                when "delete":
                  mirror.delete task.path
                when "write_to":
                  file = File.join(File.dirname(__FILE__), "../log", task.file)

                  status = mirror.write_to(task.path, File.read(file))

                  File.delete(file) if status

                  status
                else
                  raise "should not happen" # FIXME
              end
              
              if result
                break
              else
                sleep(30)
              end
            end
          end
        end
      end
    end
  end
end

