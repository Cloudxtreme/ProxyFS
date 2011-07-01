
require "config/database"
require "config/logger"

module ProxyFS
  class Task < ActiveRecord::Base
    validates_presence_of :command, :path, :mirror

    belongs_to :mirror

    def done
      destroy

      LOGGER.info "#{mirror.hostname}: #{command} #{path}: done"
    end
  end
end

