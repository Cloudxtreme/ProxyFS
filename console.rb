
require File.join(File.dirname(__FILE__), "config/production")

require "lib/mirror"
require "lib/task"

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

def get_pid
  pid_file = File.join(File.dirname(__FILE__), "tmp/proxyfs.pid")

  return File.read(pid_file).to_i if File.exists?(pid_file)

  return nil
end

def running?
  if get_pid
    begin
      Process.kill(0, get_pid)
    rescue Exception
      return false
    end
  end

  false
end

def kill_now
  if get_pid
    Process.kill(15, get_pid)

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

def print_errors(obj)
  obj.errors.each do |key, value|
    puts "error: #{key} - #{value}"
  end
end

def add_mirror(hostname, username, base_path)
  if running?
    puts "shut down the daemon first"
  else
    mirror = Mirror.new :hostname => hostname, :username => username, :base_path => base_path

    if mirror.save
      puts "done"
    else
      print_errors mirror
    end
  end

  nil
end

def remove_mirror(hostname)
  if running?
    puts "shut down the daemon first"
  else
    mirror = Mirror.find_by_hostname hostname

    if mirror
      mirror.destroy

      puts "done"
    else
      puts "hostname not found"
    end
  end

  nil
end

def show_help
  puts "supported commands:"
  puts "* show_help - shows this screen"
  puts "* show_status - shows a status of your mirrors"
  puts "* show_tasks - lists open tasks for all hosts"
  puts "* show_tasks '[hostname]' - lists open tasks for host"
  puts "* add_mirror '[hostname]', '[username]', '[base_path]' - add the mirror to the list"
  puts "* remove_mirror '[hostname]' - remove mirror from the list"
  puts "* try_again '[hostname]' - triggers a retry of erroneous tasks on the host"
  puts "* kill_now - kill the daemon gracefully"
end

