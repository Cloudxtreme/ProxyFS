
require File.join(File.dirname(__FILE__), "config/production")

require "fusefs"
require "escape"
require "lib/garbage_collector"
require "lib/fuse"
require "lib/mirrors"
require "lib/exit"

if ARGV.size < 2
  puts "usage: [local path] [mount point]"
  exit
end

local_path = ARGV[0]
mount_point = ARGV[1]

unless File.directory?(local_path)
  puts "not a directory: #{local_path}"
  exit
end

unless File.directory?(mount_point)
  puts "not a directory: #{mount_point}"
  exit
end

Process.daemon true

open(File.join(PROXYFS_ROOT, "tmp/proxyfs.pid"), "w") { |stream| stream.write Process.pid.to_s }

trap("SIGTERM") { ProxyFS.exit! }

FuseFS.set_root ProxyFS::Fuse.new(local_path)
FuseFS.mount_under(mount_point, "allow_other")

ProxyFS::Mirrors.instance.replicate!
ProxyFS::GarbageCollector.instance.collect!

FuseFS.run

