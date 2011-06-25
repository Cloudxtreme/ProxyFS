
module ProxyFS
  class Transaction
    @@mirrors = []

    def self.mirrors
      @@mirrors
    end

    def remote(&block)
      @remote = block
    end

    def local(&block)
      @local = block
    end

    def rewind(&block)
      @rewind = block
    end

    def run
      @@mirrors.each_with_index do |mirror, index|
        unless @remote.call mirror
          index.times do |i|
            raise "out of sync" unless @rewind.call @@mirrors[i]
          end

          return false
        end
      end

      unless @local.call
        @@mirrors.each do |mirror|
          raise "out of sync" unless @rewind.call mirror
        end

        return false
      end

      true
    end
  end
end

