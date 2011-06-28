
require "singleton"
require "queue"
require "thread"

require File.join(File.dirname(__FILE__), "mirror")

# The worker is responsible for managing the queues and garbage collection.
# It will start a thread for each mirror to replicate each operation asynchronously, but in order.

class Worker
  include Singleton

  attr_accessor :garbage

  def initialize
    @mirrors = Mirror.all

    @queues = @mirrors.collect { Queue.new }

    @garbage = Mutex.new

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
        @garbage.synchronize do
          files = Task.all.collect(&:file).to_set

          Dir.foreach(log_path) do |file|
            full_path = File.join(log_path, file)

            File.delete(full_path) if file !~ /^./ && !files.include?(file)
          end

          sleep 300
        end
      end
    end

    # start thread for each mirror

    mutex = Mutex.new

    @mirrors.each_with_index do |mirror, i|
      Thread.new do
        queue = @queues[i]

        loop do
          mutex.synchronize do # only one thread at a time uploading
            task = queue.pop

            Task.transaction do
              task.destroy! # remove task from log

              loop do
                begin
                  case task.command
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
                # rescue Timeout::Error
                #   sleep 30
                # rescue Net::SFTP::StatusException => e
                #   case e.code
                #   when Net::SSH::Constants::StatusCodes::FX_NO_CONNECTION
                #     sleep 30
                #   when Net::SSH::Constants::StatusCodes::FX_CONNECTION_LOST
                #     sleep 30
                #   when SSH_ERROR_CONNECTION_CLOSED ?
                #   when SSH_ERROR_INVALID_PACKET ?
                #   when SSH_ERROR_TUNNEL_ERROR ?
                #   else
                #     ...
                # rescue Exception
                #   ...
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
end

