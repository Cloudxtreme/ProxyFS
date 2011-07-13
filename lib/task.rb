
require "config/database"
require "config/logger"

module ProxyFS
  # Represents a log entry used to replicate operations on remote mirrors.
  # Uses ActiveRecord to let the tasks be stored at a persistence layer.
  #
  #   Task.create :command => "mkdir", :path => "/new/directory", :mirror => mirror

  class Task < ActiveRecord::Base
    validates_presence_of :command, :path, :mirror

    belongs_to :mirror

    # Marks a +Task+ as +done+, i.e. deletes the +Task+.

    def done
      destroy

      LOGGER.info "#{mirror.hostname}: #{command} #{path}: done"
    end

    # Searches for +Tasks+ for +path+ newer than +created+.
    # Returns +nil+ if none found.

    def self.any_newer?(path, created)
      find_by_path(path, :conditions => [ "created_at > ?", created ])
    end
  end
end

