require 'minitest/autorun'
require 'stringio'
require 'tmpdir'
require_relative '../tools/collect'

class CorpusTestCase < Minitest::Test
  def setup
    @root = Dir.mktmpdir
    File.write(File.join(@root, 'sources.tsv'), "repository\tpath\tcommit\tsha256\nowner/project\t\t\t\nother/project\t\t\t\n")
    @store = GemfileCorpus::Store.new(@root, kind: :gemfiles)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def add(year, data = "gem 'rake'\n", repository: 'owner/project', filename: 'Gemfile')
    @store.add(repository, year, filename, 'a' * 40, data)
  end
end
