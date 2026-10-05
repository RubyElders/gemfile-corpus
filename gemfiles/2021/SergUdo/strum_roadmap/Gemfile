# frozen_string_literal: true

source "https://rubygems.org"

# framework
gem "bundler", "~> 2"
gem "puma", "~> 4.2.0"
gem "rack-unreloader", "~> 1.7"
gem "rake", "~> 13"
gem "roda", "~> 3.28"

# database
gem "pg", "~> 1.1.4"
gem "sequel", "~> 5.24"
gem "sequel_pg", "~> 1.12"

# Strum framework
gem "strum", "~> 0.0.50"

group :development do
  # A Ruby code quality reporter
  gem "rubycritic", require: false

  # A Ruby static code analyzer and formatter,
  # based on the community Ruby style guide. https://docs.rubocop.org
  gem "rubocop", "~> 0.62.0", require: false

  gem "roda-route_list"
end

group :test do
  gem "database_cleaner"
  gem "email_spec"
  gem "json_spec"
end

group :development, :test do
  # Call "byebug" anywhere in the code
  # to stop execution and get a debugger console
  gem "byebug", platforms: %i[mri mingw x64_mingw]
  gem "factory_bot"
  gem "rspec"
  gem "rspec_junit_formatter"
  gem 'ruby_jard'

  gem "debase", "~> 0.2.4"
  gem "ruby-debug-ide", "~> 0.7.0"
  gem "sequel-annotate"

  # A Ruby gem to load environment variables from `.env`.
  gem "dotenv"
end
