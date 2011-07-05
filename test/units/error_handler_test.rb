
require "test/lib/test_case"
require "test/units/fixtures"
require "lib/error_handler"

module ProxyFS
  class ErrorHandler
    @@timeout = 0.1

    attr_accessor :log_level
  end
end

class ErrorHandlerTest < ProxyFS::TestCase
  def setup
    setup_fixtures

    @handler = ProxyFS::ErrorHandler.new(fixture(:mirror), fixture(:task))
  end

  def test_handle
    assert_difference("LOGGER.size") do
      assert_difference("ActionMailer::Base.deliveries.size") do
        @handler.handle Timeout::Error
      end
    end
  end

  def test_handle_block
    assert_difference("LOGGER.size") do
      assert_difference("ActionMailer::Base.deliveries.size") do
        thread = Thread.new { @handler.handle Exception.new }

        sleep 1

        assert fixture(:task).block

        fixture(:task).block = false
        fixture(:task).save

        thread.join
      end
    end
  end

  def test_log_level
    assert_difference("LOGGER.size") do
      assert_difference("ActionMailer::Base.deliveries.size") do
        assert_equal :error, @handler.log_level

        @handler.handle Timeout::Error

        assert_equal(:fatal, @handler.log_level)
      end
    end

    assert_no_difference("LOGGER.size") do
      assert_no_difference("ActionMailer::Base.deliveries.size") do
        @handler.handle Timeout::Error
      end
    end

    assert_difference("LOGGER.size") do
      assert_difference("ActionMailer::Base.deliveries.size") do
        thread = Thread.new { @handler.handle Exception.new }

        sleep 1

        assert_equal(:error, @handler.log_level)

        thread.exit
      end
    end
  end
end

