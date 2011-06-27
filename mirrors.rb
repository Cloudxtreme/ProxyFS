
require File.join(File.dirname(__FILE__), "config/database")
require File.join(File.dirname(__FILE__), "lib/mirror")

# You can add arbitrary mirrors, available by SFTP:
# Mirror.create :hostname => "...", :username => "...", :path => "/path/to/destination"

Mirror.create :hostname => "127.0.0.1", :username => "hkf", :base_path => "/home/hkf/sync"

puts "mirrors added"

