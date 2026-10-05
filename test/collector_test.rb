require_relative 'test_helper'

class FakeGitHub
  attr_reader :downloads

  def initialize(commits: {}, samples: {}, available: true)
    @commits = commits
    @samples = samples
    @available = available
    @downloads = []
  end

  def histories(repositories, years)
    repositories.each_with_index.to_h do |_repository, index|
      next ["p#{index}", nil] unless @available

      history = years.to_h do |year|
        commit = @commits[year]
        nodes = commit ? [{ 'oid' => commit }] : []
        ["y#{year}", { 'nodes' => nodes }]
      end
      project = {
        'isPrivate' => false,
        'defaultBranchRef' => { 'target' => history }
      }
      ["p#{index}", project]
    end
  end

  def gemfile(repository, commit)
    @downloads << [repository, commit]
    sample = @samples.fetch(commit, nil)
    raise sample if sample.is_a?(Exception)

    sample
  end
end

class CollectorTest < CorpusTestCase
  def collect(github, years)
    @output = StringIO.new
    collector = GemfileCorpus::Collector.new(@store, github: github, output: @output)
    collector.collect(years, repositories: ['owner/project'])
  end

  def test_shared_commits_are_downloaded_once
    sha = 'a' * 40
    github = FakeGitHub.new(
      commits: { 2022 => sha, 2023 => sha },
      samples: { sha => ['Gemfile', "gem 'rake'\n"] }
    )
    assert_equal 0, collect(github, [2021, 2022, 2023])
    assert_equal [['owner/project', sha]], github.downloads
    assert_equal 1, @store.verify
    assert_match(/2021: no commit/, @output.string)
    assert_match(/2023: unchanged/, @output.string)
  end

  def test_download_failure_is_reported_and_counted
    sha = 'a' * 40
    github = FakeGitHub.new(
      commits: { 2021 => sha },
      samples: { sha => RuntimeError.new('download failed') }
    )
    assert_equal 1, collect(github, [2021])
    assert_match(/error: download failed/, @output.string)
    assert_empty @store.rows
  end

  def test_unavailable_repository_causes_a_failed_run
    assert_equal 1, collect(FakeGitHub.new(available: false), [2021])
    assert_match(/unavailable/, @output.string)
  end

  def test_missing_gemfile_is_reported_without_an_error
    github = FakeGitHub.new(commits: { 2021 => 'a' * 40 })
    assert_equal 0, collect(github, [2021])
    assert_match(/2021: no Gemfile/, @output.string)
    assert_empty @store.rows
  end

  def test_later_gemspec_version_excludes_all_years_before_writing
    first = 'a' * 40
    second = 'b' * 40
    github = FakeGitHub.new(
      commits: { 2021 => first, 2022 => second },
      samples: {
        first => ['Gemfile', "gem 'rake'\n"],
        second => ['Gemfile', "gemspec\n"]
      }
    )
    assert_equal 0, collect(github, [2021, 2022])
    assert_match(/excluded \(depends on a gemspec\)/, @output.string)
    assert_empty @store.rows
    refute Dir.exist?(File.join(@root, 'gemfiles'))
  end

  def test_successful_years_are_kept_when_another_download_fails
    first = 'a' * 40
    second = 'b' * 40
    github = FakeGitHub.new(
      commits: { 2021 => first, 2022 => second },
      samples: {
        first => RuntimeError.new('download failed'),
        second => ['Gemfile', "gem 'rails'\n"]
      }
    )
    assert_equal 1, collect(github, [2021, 2022])
    assert_equal 1, @store.verify
    assert_equal 'gemfiles/2022/owner/project/Gemfile', @store.rows.first.fetch('path')
  end

  def test_future_year_is_rejected
    assert_raises(RuntimeError) do
      collect(FakeGitHub.new, [Date.today.year + 1])
    end
  end
end
