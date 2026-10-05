require_relative 'test_helper'

class GitHubTest < Minitest::Test
  def test_history_query_caps_the_current_year_at_collection_time
    now = Time.utc(2026, 10, 4)
    query = GemfileCorpus::GitHub.new.send(:history_query, ['owner/project'], [2021, 2026], now)
    assert_includes query, 'until: "2021-12-31T23:59:59Z"'
    assert_includes query, 'until: "2026-10-04T00:00:00Z"'
    refute_includes query, '2026-12-31'
  end

  def test_history_query_gives_each_repository_a_distinct_alias
    now = Time.utc(2026, 10, 4)
    query = GemfileCorpus::GitHub.new.send(:history_query, ['owner/first', 'other/second'], [2021], now)
    assert_includes query, 'p0: repository(owner: "owner", name: "first")'
    assert_includes query, 'p1: repository(owner: "other", name: "second")'
  end
end
