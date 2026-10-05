require_relative 'store_test'
require_relative 'declarations_test'
require_relative 'github_test'
require_relative 'collector_test'

class CollectedCorpusTest < Minitest::Test
  def test_collected_files
    store = GemfileCorpus::Store.new(File.expand_path('..', __dir__))
    assert_operator store.verify, :>, 1000
  end
end
