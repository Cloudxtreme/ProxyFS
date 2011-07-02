
require File.join(File.dirname(__FILE__), "environments/production")

require "config/database"
require "db/migrations/create_mirrors"
require "db/migrations/create_tasks"

CreateMirrors.up
CreateTasks.up

