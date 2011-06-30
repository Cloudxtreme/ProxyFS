
require "fusefs"
require File.expand_path File.join(File.dirname(__FILE__), "lib/garbage_collector")
require File.expand_path File.join(File.dirname(__FILE__), "lib/proxy_fuse")
require File.expand_path File.join(File.dirname(__FILE__), "lib/mirrors")

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

FuseFS.set_root ProxyFS::ProxyFuse.new(local_path)
FuseFS.mount_under(mount_point, "allow_other")

ProxyFS::Mirrors.instance.replicate!
ProxyFS::GarbageCollector.instance.collect!

FuseFS.run

