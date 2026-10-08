module GemfileCorpus
  REPOSITORY = /\A[A-Za-z0-9_-][A-Za-z0-9_.-]*\/[A-Za-z0-9_-][A-Za-z0-9_.-]*\z/
  SAMPLE = %r{\A(?:gemfiles|lockfiles)/(\d{4})/([A-Za-z0-9_-][A-Za-z0-9_.-]*/[A-Za-z0-9_-][A-Za-z0-9_.-]*)/(Gemfile|gems\.rb|Gemfile\.lock|gems\.locked)\z}
end

require 'ripper'

module GemfileCorpus
  module Declarations
    def self.uses_gemspec?(content)
      syntax = Ripper.sexp(content)
      raise 'Gemfile could not be parsed' unless syntax

      gemspec_call?(syntax)
    end

    def self.gemspec_call?(node)
      return false unless node.is_a?(Array)

      method = case node.first
               when :vcall, :fcall, :command then node[1]
               when :call, :command_call then node[3]
               end
      return true if method.is_a?(Array) && %w[gemspec load_gemspec].include?(method[1])

      node.any? { |child| gemspec_call?(child) }
    end
    private_class_method :gemspec_call?
  end
end

require 'csv'
require 'digest'
require 'fileutils'
require 'tempfile'

module GemfileCorpus
  class Store
    COLUMNS = %w[repository path commit sha256].freeze

    attr_reader :kind

    def initialize(root, kind:)
      raise 'Invalid corpus kind' unless %i[gemfiles lockfiles].include?(kind)

      @kind = kind
      @filenames = kind == :gemfiles ? %w[Gemfile gems.rb] : %w[Gemfile.lock gems.locked]
      @root = File.expand_path(root)
    end

    def repositories
      records.map { |row| row.fetch('repository') }.uniq.tap do |names|
        raise 'Invalid repository list' unless names.all? { |name| REPOSITORY.match?(name.to_s) }
      end
    end

    def records
      path = File.join(@root, 'sources.tsv')
      return [] unless File.exist?(path)

      table = CSV.read(path, headers: true, col_sep: "\t")
      raise 'Invalid provenance header' unless table.headers == COLUMNS

      table.map(&:to_h).tap do |entries|
        entries.each do |row|
          if row.fetch('path').to_s.empty? && %w[commit sha256].any? { |key| !row.fetch(key).to_s.empty? }
            raise 'Repository without a snapshot has provenance'
          end
        end
      end
    end

    def rows
      records.select { |row| row.fetch('path').to_s.start_with?("#{@kind}/") }
    end

    def save(entries)
      other = records.reject { |row| row.fetch('path').to_s.empty? || row.fetch('path').start_with?("#{@kind}/") }
      entries = entries + other
      pending = repositories - entries.map { |row| row.fetch('repository') }
      entries = entries + pending.map { |repository| COLUMNS.to_h { |key| [key, key == 'repository' ? repository : ''] } }
      text = CSV.generate(col_sep: "\t") do |csv|
        csv << COLUMNS
        entries.sort_by { |row| [row.fetch('repository'), row.fetch('path')] }.each { |row| csv << COLUMNS.map { |key| row.fetch(key) } }
      end
      Tempfile.create(['sources', '.tsv'], @root) do |file|
        file.write(text)
        file.close
        File.rename(file.path, File.join(@root, 'sources.tsv'))
      end
    end

    def add(repository, year, filename, commit, data)
      raise 'Invalid repository' unless REPOSITORY.match?(repository)
      raise 'Invalid year' unless (1900..9999).cover?(year)
      raise 'Invalid filename' unless @filenames.include?(filename)
      raise 'Invalid commit' unless /\A[0-9a-f]{40}\z/.match?(commit)

      raise 'Gemfile depends on a gemspec' if @kind == :gemfiles && Declarations.uses_gemspec?(data)

      entries = rows
      checksum = Digest::SHA256.hexdigest(data)
      duplicate = entries.find do |row|
        SAMPLE.match(row.fetch('path'))[2] == repository && row.fetch('sha256') == checksum &&
          (@kind == :gemfiles || File.basename(row.fetch('path')) == filename)
      end
      path = "#{@kind}/#{year}/#{repository}/#{filename}"
      destination = File.join(@root, path)
      if duplicate
        return :unchanged if duplicate.fetch('path').split('/')[1].to_i <= year

        raise "Existing sample differs: #{path}" if File.exist?(destination)
        FileUtils.mkdir_p(File.dirname(destination))
        FileUtils.mv(File.join(@root, duplicate.fetch('path')), destination)
        entries.delete(duplicate)
      else
        raise "Existing sample differs: #{path}" if File.exist?(destination)
        FileUtils.mkdir_p(File.dirname(destination))
        File.binwrite(destination, data)
      end
      entries << { 'repository' => repository, 'path' => path, 'commit' => commit, 'sha256' => checksum }
      save(entries)
      :stored
    end

    def verify(duplicates: true)
      entries = rows
      paths = entries.map { |row| row.fetch('path') }
      actual = Dir.glob(File.join(@root, @kind.to_s, '**', '*'), File::FNM_DOTMATCH)
                  .select { |path| File.file?(path) || File.symlink?(path) }
                  .map { |path| path.delete_prefix(@root + '/') }
      raise 'Files do not match provenance' unless paths.uniq == paths && paths.sort == actual.sort

      known = {}
      projects = repositories
      entries.each do |row|
        match = SAMPLE.match(row.fetch('path'))
        raise "Invalid sample: #{row['path']}" unless match && @filenames.include?(match[3]) && match[2] == row.fetch('repository') && projects.include?(match[2])
        raise 'Invalid commit' unless /\A[0-9a-f]{40}\z/.match?(row.fetch('commit'))
        file = File.join(@root, row.fetch('path'))
        raise "Symlink sample: #{file}" if File.symlink?(file)
        checksum = Digest::SHA256.file(file).hexdigest
        raise "Checksum differs: #{file}" unless checksum == row.fetch('sha256')
        raise "Gemfile depends on a gemspec: #{file}" if @kind == :gemfiles && Declarations.uses_gemspec?(File.binread(file))

        key = [match[2], checksum, @kind == :lockfiles ? match[3] : nil]
        raise "Duplicate sample: #{row['path']}" if duplicates && known[key]
        known[key] = true
      end
      entries.length
    end

    def deduplicate
      verify(duplicates: false)
      entries = rows
      retained = entries.group_by { |row| [SAMPLE.match(row.fetch('path'))[2], row.fetch('sha256'), @kind == :lockfiles ? File.basename(row.fetch('path')) : nil] }
                        .values.map { |group| group.min_by { |row| row.fetch('path') } }
      (entries - retained).each { |row| File.delete(File.join(@root, row.fetch('path'))) }
      save(retained)
      entries.length - retained.length
    end
  end
end

require 'json'
require 'net/http'
require 'open3'
require 'time'

module GemfileCorpus
  class GitHub
    MAX_BYTES = 2 * 1024 * 1024

    def histories(repositories, years, now: Time.now.utc)
      query = history_query(repositories, years, now)
      output, error, status = Open3.capture3(
        'gh', 'api', 'graphql', '--input', '-',
        stdin_data: JSON.generate(query: query)
      )
      history_response(output, error, status.success?)
    end

    def gemfile(repository, commit)
      %w[Gemfile gems.rb].each do |filename|
        uri = URI("https://raw.githubusercontent.com/#{repository}/#{commit}/#{filename}")
        content = download(uri)
        return [filename, content] if content
      end
      nil
    end

    def lockfiles(repository, commit)
      %w[Gemfile.lock gems.locked].filter_map do |filename|
        content = download(URI("https://raw.githubusercontent.com/#{repository}/#{commit}/#{filename}"))
        [filename, content] if content
      end
    end

    private

    def history_response(output, error, success)
      response = JSON.parse(output.empty? ? '{}' : output)
      errors = response.fetch('errors', [])
      missing_only = !errors.empty? && errors.all? { |entry| entry['type'] == 'NOT_FOUND' }
      raise "GitHub API failed: #{error}" unless success || (missing_only && response['data'])
      raise "GitHub query failed: #{errors}" unless errors.empty? || missing_only

      response.fetch('data')
    end

    def history_query(repositories, years, now)
      fields = years.map do |year|
        cutoff = [Time.utc(year, 12, 31, 23, 59, 59), now].min.iso8601
        <<~GRAPHQL
          y#{year}: history(first: 1, until: #{cutoff.to_json}) {
            nodes { oid committedDate }
          }
        GRAPHQL
      end.join("\n")

      projects = repositories.each_with_index.map do |repository, index|
        owner, name = repository.split('/')
        <<~GRAPHQL
          p#{index}: repository(owner: #{owner.to_json}, name: #{name.to_json}) {
            isPrivate
            defaultBranchRef {
              target {
                ... on Commit {
                  #{fields}
                }
              }
            }
          }
        GRAPHQL
      end
      "{\n#{projects.join("\n")}\n}"
    end

    def download(uri)
      content = nil
      Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 15, read_timeout: 45) do |http|
        http.request(Net::HTTP::Get.new(uri)) do |response|
          next if response.code == '404'
          raise "Download failed: HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

          content = String.new(encoding: Encoding::BINARY)
          response.read_body do |chunk|
            content << chunk
            raise 'Downloaded file exceeds 2 MiB' if content.bytesize > MAX_BYTES
          end
        end
      end
      content
    end
  end
end

require 'date'

module GemfileCorpus
  class Collector
    def initialize(store, github: GitHub.new, output: $stdout)
      @store = store
      @github = github
      @output = output
      @store_lock = Mutex.new
    end

    def collect(years, repositories: @store.repositories)
      raise 'Invalid years' if years.empty? || years.any? { |year| !(1900..Date.today.year).cover?(year) }
      raise 'Invalid repositories' unless repositories.all? { |repo| REPOSITORY.match?(repo) }

      years = years.sort.uniq
      repositories.each_slice(20).sum do |batch|
        projects = @github.histories(batch, years)
        if @store.kind == :lockfiles
          queue = Queue.new
          batch.each_with_index { |repository, index| queue << [repository, projects.fetch("p#{index}")] }
          4.times.map do
            Thread.new do
              failures = 0
              loop do
                item = begin
                  queue.pop(true)
                rescue ThreadError
                  break
                end
                failures += collect_project(*item, years)
              end
              failures
            end
          end.sum(&:value)
        else
          batch.each_with_index.sum do |repository, index|
            collect_project(repository, projects.fetch("p#{index}"), years)
          end
        end
      end
    end

    private

    def collect_project(repository, project, years)
      if project.nil? || project.fetch('isPrivate') || project['defaultBranchRef'].nil?
        @output.puts "#{repository}: unavailable"
        return 1
      end

      commits = project.fetch('defaultBranchRef').fetch('target')
      downloads = {}
      samples = {}
      failures = 0
      years.each do |year|
        begin
          sample = download_year(repository, year, commits, downloads)
          next unless sample

          if @store.kind == :gemfiles && Declarations.uses_gemspec?(sample.first.last)
            @output.puts "#{repository}: excluded (depends on a gemspec)"
            return failures
          end
          samples[year] = sample
        rescue StandardError => error
          @output.puts "#{repository} #{year}: error: #{error.message}"
          failures += 1
        end
      end

      failures + samples.sum do |year, sample|
        sample.sum { |entry| store_year(repository, year, entry) }
      end
    end

    def download_year(repository, year, commits, downloads)
      commit = commits.fetch("y#{year}").fetch('nodes').first
      unless commit
        @output.puts "#{repository} #{year}: no commit"
        return
      end

      sha = commit.fetch('oid')
      unless downloads.key?(sha)
        downloads[sha] = if @store.kind == :lockfiles
                          @github.lockfiles(repository, sha)
                        else
                          sample = @github.gemfile(repository, sha)
                          sample ? [sample] : []
                        end
      end
      sample = downloads[sha]
      if sample.empty?
        label = @store.kind == :lockfiles ? "lockfile" : "Gemfile"
        @output.puts "#{repository} #{year}: no #{label}"
        return
      end

      sample.map { |entry| [sha, *entry] }
    end

    def store_year(repository, year, sample)
      sha, filename, content = sample
      result = @store_lock.synchronize { @store.add(repository, year, filename, sha, content) }
      @output.puts "#{repository} #{year}: #{result}"
      0
    rescue StandardError => error
      @output.puts "#{repository} #{year}: error: #{error.message}"
      1
    end
  end
end
