
require "active_record"

ActiveRecord::Base.establish_connection(
  :adapter => "mysql",
  :hostname => "127.0.0.1",
  :username => "root",
  :password => "",
  :database => "proxyfs"
)

