
require "lib/proxyfs"
require "lib/proxyfs/mirror"
require "lib/proxyfs/transaction"
require "fusefs"
require "yaml"

if ARGV.empty?
  puts "usage: [config file]"
  exit
end

config = YAML.load File.read(ARGV.shift)

config["mirrors"].values.each do |mirror|
  ProxyFS::Transaction.mirrors.push ProxyFS::Mirror.new(mirror["user"], mirror["host"], mirror["path"], config["tries"], config["timeout"])
end

FuseFS.set_root ProxyFS::ProxyFS.new(config["local_path"])
FuseFS.mount_under config["mount_point"]
FuseFS.run

