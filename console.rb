
require File.join(File.dirname(__FILE__), "environments/production")

require "lib/mirror"
require "lib/task"
require "escape"

include ProxyFS

def show_status
  puts "#{Mirror.count} mirrors"

  Mirror.all.each do |mirror|
    puts "#{mirror.username}@#{mirror.hostname} -> #{mirror.base_path}"
  end

  nil
end

def try_again(hostname)
  mirror = Mirror.find_by_hostname hostname

  if mirror
    mirror.tasks.each do |task|
      task.block = false
      task.save
    end

    puts "done (unblocked)"
  else
    puts "hostname not found"
  end

  nil
end

def show_tasks(hostname = nil)
  if hostname
    mirror = Mirror.find_by_hostname hostname

    if mirror
      puts "#{mirror.tasks.size} tasks"

      mirror.tasks.each do |task|
        puts "#{task.command} #{task.path}"
      end
    else
      puts "hostname not found"
    end
  else
    puts "#{Task.count} tasks"

    Task.all.each do |task|
      puts "#{task.command} #{task.path}"
    end
  end

  nil
end

def kill_now
  pid_file = File.join(File.dirname(__FILE__), "tmp/proxyfs.pid")

  if File.exists?(pid_file)
    pid = File.read pid_file

    if pid =~ /^[0-9]+/
      system Escape.shell_command([ "/bin/kill", pid ]).to_s
    end

    puts "done"
  else
    puts "not found"
  end

  nil
end

def skip_one(hostname)
  # TODO
end

def skip_all(hostname)
  # TODO
end

def add_mirror(hostname, username, path)
  # TODO
end

def remove_mirror(hostname)
  # TODO
end

def show_help
  puts "supported commands:"
  puts "* show_help - shows this screen"
  puts "* show_status - shows a status of your mirrors"
  puts "* show_tasks - lists open tasks for all hosts"
  puts "* show_tasks [hostname] - lists open tasks for host"
  puts "* try_again [hostname] - triggers a retry of erroneous tasks on the host"
  puts "* kill_now - kill the daemon gracefully"
end

