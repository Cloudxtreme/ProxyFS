# The ProxyFS console is a powerful tool to manage your mirrors and tasks, start/stop
# the daemon and so on. To start the console, run from the ProxyFS root directory:
#
#   $ irb -r console.rb
#
# To become familiar with the console, run:
#
#   > show_help
#
# The output will look like:
#
#   * show_help - shows this screen
#   * show_status - shows a status of your mirrors
#   * show_tasks - lists open tasks for all hosts
#   * show_tasks '[hostname]' - lists open tasks for host
#   * add_mirror '[hostname]', '[username]', '[base_path]' - add the mirror to the list
#   * remove_mirror '[hostname]' - remove mirror from the list
#   * try_again '[hostname]' - triggers a retry of erroneous tasks on the host
#   * kill_now - kill the daemon gracefully
#
# To leave the console, run:
#
#   > quit

require File.join(File.dirname(__FILE__), "config/production")

require "lib/mirror"
require "lib/task"

include ProxyFS

# Prints a list of your currently existing mirrors.

def show_status
  puts "#{Mirror.count} mirrors"

  Mirror.all.each do |mirror|
    puts "#{mirror.username}@#{mirror.hostname} -> #{mirror.base_path}"
  end

  nil
end

# Marks the current blocked (i.e. erroneous) task for mirror +hostname+ as fixed, to let the replication retry.

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

# Prints open tasks. If +hostname+ is given, tasks are only shown for the +Mirror+ having +hostname+.
 
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

# Returns the PID of the running daemon.

def get_pid
  pid_file = File.join(File.dirname(__FILE__), "tmp/proxyfs.pid")

  return File.read(pid_file).to_i if File.exists?(pid_file)

  return nil
end

# Returns true if the daemon is running.

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

# Kills the daemon gracefully by sending a SIGTERM to the process.

def kill_now
  if get_pid
    Process.kill(15, get_pid)

    puts "done"
  else
    puts "not found"
  end

  nil
end

# +skip_one+ is not yet implemented.

def skip_one(hostname)
  # TODO
end

# +skip_all+ is not yet implemented.

def skip_all(hostname)
  # TODO
end

# Pretty prints ActiveRecord errors for +obj+.

def print_errors(obj)
  obj.errors.each do |key, value|
    puts "error: #{key} - #{value}"
  end
end

# Adds a +Mirror+ defined by +hostname+, +username+ and +base_path+.
# Right now, only key based authentication is supported.
# To add a +Mirror+, you have to shut down the daemon first using +kill_now+.

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

# Removes the +Mirror+ having +hostname+ from your active mirrors.
# To remove a +Mirror+, you have to shut down the daemon first using +kill_now+.

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

# Prints a list of available commands.

def show_help
  puts "* show_help - shows this screen"
  puts "* show_status - shows a status of your mirrors"
  puts "* show_tasks - lists open tasks for all hosts"
  puts "* show_tasks '[hostname]' - lists open tasks for host"
  puts "* add_mirror '[hostname]', '[username]', '[base_path]' - add the mirror to the list"
  puts "* remove_mirror '[hostname]' - remove mirror from the list"
  puts "* try_again '[hostname]' - triggers a retry of erroneous tasks on the host"
  puts "* kill_now - kill the daemon gracefully"
end

