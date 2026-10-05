require_relative 'test_helper'

class StoreTest < CorpusTestCase
  def test_unchanged_years_keep_one_copy
    assert_equal :stored, add(2021)
    assert_equal :unchanged, add(2022)
    assert_equal :unchanged, add(2026)
    assert_equal 1, @store.verify
    assert_equal 'gemfiles/2021/owner/project/Gemfile', @store.rows.first.fetch('path')
  end

  def test_earlier_identical_version_moves_the_copy
    add(2026)
    assert_equal :stored, add(2021)
    assert_equal 1, @store.verify
    refute File.exist?(File.join(@root, 'gemfiles/2026/owner/project/Gemfile'))
    assert_equal 'gemfiles/2021/owner/project/Gemfile', @store.rows.first.fetch('path')
  end

  def test_changed_version_is_retained
    add(2021)
    add(2022, "gem 'rails'\n")
    assert_equal 2, @store.verify
  end

  def test_matching_content_in_different_projects_stays_separate
    add(2021)
    add(2021, repository: 'other/project')
    assert_equal 2, @store.verify
  end

  def test_gems_rb_keeps_original_name_and_binary_bytes
    bytes = "# \xff\ngem 'rake'\n".b
    add(2021, bytes, filename: 'gems.rb')
    assert_equal bytes, File.binread(File.join(@root, 'gemfiles/2021/owner/project/gems.rb'))
    assert_equal 1, @store.verify
  end

  def test_changed_file_in_same_year_does_not_overwrite
    add(2021)
    assert_raises(RuntimeError) { add(2021, 'changed') }
    assert_equal 1, @store.verify
    assert_equal "gem 'rake'\n", File.binread(File.join(@root, 'gemfiles/2021/owner/project/Gemfile'))
  end

  def test_invalid_paths_and_other_files_are_rejected
    assert_raises(RuntimeError) { add(2021, repository: '../project') }
    assert_raises(RuntimeError) { add(2021, filename: 'LICENSE') }
    assert_raises(RuntimeError) { add(1899) }
    refute Dir.exist?(File.join(@root, 'gemfiles'))
  end

  def test_verify_detects_modified_content
    add(2021)
    File.binwrite(File.join(@root, 'gemfiles/2021/owner/project/Gemfile'), 'changed')
    assert_match(/Checksum differs/, assert_raises(RuntimeError) { @store.verify }.message)
  end

  def test_verify_detects_unindexed_files
    add(2021)
    File.write(File.join(@root, 'gemfiles/2021/owner/project/LICENSE'), 'extra')
    assert_match(/provenance/, assert_raises(RuntimeError) { @store.verify }.message)
  end

  def test_repository_seeds_survive_collection_and_deduplication
    assert_equal ['owner/project', 'other/project'], @store.repositories
    add(2021)
    @store.deduplicate
    assert_equal ['other/project', 'owner/project'], @store.repositories
    assert_equal 1, @store.verify
  end

  def test_invalid_repository_seed_is_rejected
    File.write(File.join(@root, 'sources.tsv'), "repository\tpath\tcommit\tsha256\n../project\t\t\t\n")
    assert_match(/Invalid repository list/, assert_raises(RuntimeError) { @store.verify }.message)
  end

  def test_seed_with_provenance_but_no_path_is_rejected
    File.write(File.join(@root, 'sources.tsv'), "repository\tpath\tcommit\tsha256\nowner/project\t\tabc\t\n")
    assert_match(/without a snapshot/, assert_raises(RuntimeError) { @store.verify }.message)
  end

  def test_provenance_must_match_repository
    add(2021)
    @store.save(@store.rows.map { |row| row.merge('repository' => 'other/project') })
    assert_match(/Invalid sample/, assert_raises(RuntimeError) { @store.verify }.message)
  end

  def test_gemspec_dependency_is_rejected_before_writing
    assert_match(/depends on a gemspec/, assert_raises(RuntimeError) { add(2021, 'gemspec') }.message)
    assert_empty @store.rows
    refute Dir.exist?(File.join(@root, 'gemfiles'))
  end

  def test_verify_rejects_gemspec_calls_even_when_the_checksum_matches
    add(2021)
    row = @store.rows.first
    content = "gemspec\n"
    File.binwrite(File.join(@root, row.fetch('path')), content)
    @store.save([row.merge('sha256' => Digest::SHA256.hexdigest(content))])
    assert_match(/depends on a gemspec/, assert_raises(RuntimeError) { @store.verify }.message)
  end

  def test_deduplicate_removes_later_copy
    add(2021)
    path = 'gemfiles/2022/owner/project/Gemfile'
    FileUtils.mkdir_p(File.dirname(File.join(@root, path)))
    File.write(File.join(@root, path), "gem 'rake'\n")
    @store.save(@store.rows + [@store.rows.first.merge('path' => path)])
    assert_match(/Duplicate/, assert_raises(RuntimeError) { @store.verify }.message)
    assert_equal 1, @store.deduplicate
    assert_equal 1, @store.verify
    assert_equal 0, @store.deduplicate
  end
end
