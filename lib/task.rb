
require File.join(File.dirname(__FILE__), "../config/database")

class Task < ActiveRecord::Base
  validates_presence_of :command, :path
end

