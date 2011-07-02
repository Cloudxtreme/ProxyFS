
require "active_record"

if PROXYFS_ENV == :test
  ActiveRecord::Base.establish_connection(
    :adapter => "mysql",
    :hostname => "127.0.0.1",
    :username => "root",
    :password => "",
    :database => "proxyfs_test"
  )
else
  ActiveRecord::Base.establish_connection(
    :adapter => "mysql",
    :hostname => "127.0.0.1",
    :username => "root",
    :password => "",
    :database => "proxyfs"
  )
end

