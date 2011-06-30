
require File.expand_path File.join(File.dirname(__FILE__), "../config/database")
require File.expand_path File.join(File.dirname(__FILE__), "../config/logger")

module ProxyFS
  class Task < ActiveRecord::Base
    validates_presence_of :command, :path

    belongs_to :mirror

    def done!
      destroy

      LOGGER.info "#{mirror.hostname}: #{command} #{path}: done"
    end
  end
end

