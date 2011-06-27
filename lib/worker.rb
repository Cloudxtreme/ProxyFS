
require "singleton"
require "queue"

require File.join(File.dirname(__FILE__), "mirror")

# The worker is responsible for managing the queues and garbage collection.
# It will start a thread for each mirror to replicate each operation asynchronously, but in order.

class Worker
  include Singleton

  def initialize
    @mirrors = Mirror.all

    @queues = @mirrors.collect { Queue.new }

    @mirrors.each_with_index do |mirror, i|
      mirror.tasks.each do |task|
        @queues[i].push task
      end
    end
  end

  # Add +tasks+ to the queue. The size of +tasks+ should match the number of mirrors.
  # Otherwise, the method will return false.

  def add(tasks)
    return false if tasks.size != @queues.size

    @queues.each_with_index do |queue, i|
      queue.push tasks[i]
    end

    true
  end

  # Starts multiple threads. One for garbage collection of temporary files.
  # One for each mirror to replicate each operation.

  def work!
    # garbage collector

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

    # start thread for each mirror

    @mirrors.each_with_index do |mirror, i|
      Thread.new do
        queue = @queues[i]

        loop do
          task = queue.pop

          Task.transaction do
            task.destroy! # remove task from log

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
                # error occurred, sleep some time, then try again

                sleep 30
              end
            end
          end
        end
      end
    end
  end
end

