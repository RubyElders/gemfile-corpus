require_relative 'test_helper'

class DeclarationsTest < Minitest::Test
  def test_gemspec_calls_are_detected
    [
      'gemspec',
      "gemspec(path: 'subproject')",
      "group :test do; gemspec; end",
      "Bundler.load_gemspec('project.gemspec')"
    ].each do |content|
      assert GemfileCorpus::Declarations.uses_gemspec?(content), content
    end
  end

  def test_comments_strings_symbols_variables_and_method_definitions_are_ignored
    [
      "# gemspec\ngem 'rake'",
      "gem 'gemspec'",
      "message = 'gemspec'",
      "name = :gemspec",
      'gemspec = 1; puts gemspec',
      'def gemspec; end'
    ].each do |content|
      refute GemfileCorpus::Declarations.uses_gemspec?(content), content
    end
  end

  def test_invalid_ruby_is_reported
    assert_raises(RuntimeError) { GemfileCorpus::Declarations.uses_gemspec?('gem(') }
  end
end
