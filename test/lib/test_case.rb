
module ProxyFS
  class TestCase < Test::Unit::TestCase
    def assert_difference(str, difference = 1)
      first = eval str

      first = first.dup rescue first

      yield

      assert_equal(difference, eval(str) - first)
    end

    def assert_no_difference(str, &block)
      first = eval str

      first = first.dup rescue first

      yield

      assert_equal(first, eval(str))
    end
  end
end

