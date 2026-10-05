# frozen_string_literal: false

source 'https://rubygems.org'
ruby '2.4.2'

# infrastructure related
gem 'http'

# Development/Debugging related
gem 'pry' # to run console in production
gem 'rake' # to run console in production

# Web related
gem 'econfig'
gem 'puma'
gem 'rack-flash3'
gem 'roda'
gem 'slim'

# Application related
gem 'dry-transaction'
gem 'dry-validation'
gem 'multi_json'
gem 'roar'

group :test do
  gem 'headless'
  gem 'minitest'
  gem 'minitest-rg'
  gem 'page-object'
  gem 'rack-test'
  gem 'watir'
end

group :development, :test do
  gem 'rerun'

  gem 'flog'
  gem 'reek'
  gem 'rubocop'
end
