
require "test/lib/test_case"
require "lib/logger"

class LoggerTest < ProxyFS::TestCase
  def setup
    @logger = ProxyFS::Logger.new File.join(File.dirname(__FILE__), "../../log/test.log")
  end

  def test_info
    assert_difference("@logger.size") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        @logger.info "test"
      end
    end
  end

  def test_error
    assert_difference("@logger.size") do
      assert_difference("ActionMailer::Base.deliveries.size") do
        @logger.error "test"
      end
    end
  end

  def test_fatal
    assert_difference("@logger.size") do
      assert_difference("ActionMailer::Base.deliveries.size") do
        @logger.fatal "test"
      end
    end
  end
end

