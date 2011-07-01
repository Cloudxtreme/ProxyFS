
require "test/lib/test_case"
require "lib/rand32"

class Rand32Test < ProxyFS::TestCase
  def test_rand32
    assert ProxyFS.rand32.to_s =~ /^[0-9]+$/
  end
end

