# ##
# ./Gemfile

source "https://rubygems.org"

# Web framework: Core
gem "puma"
gem "roda"
gem 'logging'
gem 'json'

# General Utilities
gem 'skn_utils', ">= 5.8.0"

# Web Security
gem 'jwt'

group :development, :test do
  gem 'rake'
  gem 'pry'
  gem 'racksh'
end

group :test do
  gem 'rspec'
  gem "rack-test"
  gem 'rspec-roda'
  gem 'simplecov', :require => false
end
