
require "active_record"

ActiveRecord::Base.establish_connection(
  :adapter => "sqlite3",
  :database => File.join(File.dirname(__FILE__), "../db/database.sqlite3"),
  :pool => 5,
  :timeout => 5000
)

