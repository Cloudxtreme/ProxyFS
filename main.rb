
require File.join(File.dirname(__FILE__), "lib/proxyfs")
require "fusefs"

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

FuseFS.set_root ProxyFS.new(local_path)
FuseFS.mount_under mount_point
FuseFS.run

