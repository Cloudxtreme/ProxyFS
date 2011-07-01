
require "lib/task"
require "lib/mirror"

module ProxyFS
  class TestCase
    def setup_fixtures
      Mirror.destroy_all
      Task.destroy_all

      @fixtures = {}

      @fixtures[:mirror] = Mirror.create :hostname => "127.0.0.1", :username => "test", :base_path => "/home/test"
      @fixtures[:task] = Task.create :command => "mkdir", :path => "/test", :mirror => @fixtures[:mirror]
    end

    def fixture(key)
      @fixtures[key]
    end
  end
end

