require_relative 'collect'

root = File.expand_path('..', __dir__)
store = GemfileCorpus::Store.new(root, kind: :lockfiles)
begin
  failures = GemfileCorpus::Collector.new(store).collect((2021..Time.now.year).to_a)
  puts "Removed #{store.deduplicate} duplicate lockfiles"
  puts "Verified #{store.verify} lockfiles"
  exit 1 unless failures.zero?
rescue StandardError => error
  warn error.message
  exit 1
end
