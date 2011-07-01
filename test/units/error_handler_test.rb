
require "test/lib/test_case"
require "test/units/fixtures"
require "lib/error_handler"

module ProxyFS
  class ErrorHandler
    @@timeout = 0.1
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
end

