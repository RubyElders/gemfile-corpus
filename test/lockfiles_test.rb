require_relative 'collector_test'

class FakeLockfileGitHub < FakeGitHub
  def lockfiles(repository, commit)
    sample = gemfile(repository, commit)
    sample || []
  end
end

class LockfilesTest < CorpusTestCase
  def setup
    super
    @locks = GemfileCorpus::Store.new(@root, kind: :lockfiles)
  end

  def test_gemspec_based_files_and_unparseable_content_are_kept_as_bytes
    bytes = "gemspec\n\xff".b
    @locks.add('owner/project', 2021, 'Gemfile.lock', 'a' * 40, bytes)
    assert_equal bytes, File.binread(File.join(@root, @locks.rows.first.fetch('path')))
    assert_equal 1, @locks.verify
  end

  def test_stores_remain_independent_and_share_one_repository_list
    add(2021)
    @locks.add('owner/project', 2021, 'gems.locked', 'a' * 40, 'locked')
    add(2022, "gem 'rails'\n")
    assert_equal 2, @store.verify
    assert_equal 1, @locks.verify
    assert_equal @store.repositories, @locks.repositories
    assert_equal 0, @locks.deduplicate
    assert_equal 2, @store.verify
  end

  def test_equal_lockfiles_keep_the_earliest_year_and_original_filename
    @locks.add('owner/project', 2026, 'gems.locked', 'a' * 40, 'locked')
    @locks.add('owner/project', 2021, 'gems.locked', 'b' * 40, 'locked')
    assert_equal :unchanged, @locks.add('owner/project', 2023, 'gems.locked', 'c' * 40, 'locked')
    assert_equal 'lockfiles/2021/owner/project/gems.locked', @locks.rows.first.fetch('path')
    assert_equal 'b' * 40, @locks.rows.first.fetch('commit')
    assert_equal 1, @locks.verify
  end

  def test_coexisting_names_are_both_retained_even_with_identical_content
    %w[Gemfile.lock gems.locked].each do |filename|
      @locks.add('owner/project', 2021, filename, 'a' * 40, 'locked')
    end
    assert_equal 2, @locks.verify
    assert_equal 0, @locks.deduplicate
    assert_raises(RuntimeError) { @locks.add('owner/project', 2022, 'Gemfile', 'a' * 40, 'wrong') }
    assert_raises(RuntimeError) { add(2022, 'wrong', filename: 'Gemfile.lock') }
  end

  def test_collects_both_names_once_per_commit_without_gemspec_filtering
    sha = 'a' * 40
    github = FakeLockfileGitHub.new(
      commits: { 2021 => sha, 2022 => sha },
      samples: { sha => [['Gemfile.lock', 'gemspec'], ['gems.locked', 'also locked']] }
    )
    output = StringIO.new
    collector = GemfileCorpus::Collector.new(@locks, github: github, output: output)
    assert_equal 0, collector.collect([2021, 2022], repositories: ['owner/project'])
    assert_equal [['owner/project', sha]], github.downloads
    assert_equal 2, @locks.verify
    assert_match(/2022: unchanged/, output.string)
  end
end

class ParallelLockfilesTest < CorpusTestCase
  def test_parallel_projects_keep_all_provenance_without_losing_seeds
    locks = GemfileCorpus::Store.new(@root, kind: :lockfiles)
    sha = 'a' * 40
    github = FakeLockfileGitHub.new(
      commits: { 2021 => sha }, samples: { sha => [['Gemfile.lock', 'locked']] }
    )
    repositories = %w[one/project two/project three/project four/project]
    collector = GemfileCorpus::Collector.new(locks, github: github, output: StringIO.new)
    assert_equal 0, collector.collect([2021], repositories: repositories)
    assert_equal 4, locks.verify
    assert_equal repositories.sort, locks.rows.map { |row| row.fetch('repository') }.sort
    assert_includes locks.repositories, 'owner/project'
    assert_equal 0, @store.verify
  end
end

class LockfileDownloadTest < Minitest::Test
  def test_both_names_are_requested_at_the_immutable_commit
    github = GemfileCorpus::GitHub.new
    requests = []
    github.define_singleton_method(:download) do |uri|
      requests << uri.path
      uri.path.end_with?('gems.locked') ? 'lock bytes' : nil
    end
    sha = 'a' * 40
    assert_equal [['gems.locked', 'lock bytes']], github.lockfiles('owner/project', sha)
    assert_equal ["/owner/project/#{sha}/Gemfile.lock", "/owner/project/#{sha}/gems.locked"], requests
  end
end
