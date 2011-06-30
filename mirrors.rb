
$LOAD_PATH.unshift File.dirname(__FILE__)

require "config/database"
require "lib/mirror"
require "db/migrations/create_mirrors"
require "db/migrations/create_tasks"

CreateMirrors.up
CreateTasks.up

# You can add arbitrary mirrors, available by SFTP:
# Mirror.create :hostname => "...", :username => "...", :path => "/path/to/destination"

Mirror.create! :hostname => "127.0.0.1", :username => "hkf", :base_path => "/home/hkf/sync"

