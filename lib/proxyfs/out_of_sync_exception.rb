
module ProxyFS
  class OutOfSyncException < Exception
    def initialize
      super

      Try.logger.error "out of sync"
    end
  end
end

