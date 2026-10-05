# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'puma'
gem 'rake'

gem 'rack-unreloader', require: 'rack/unreloader'
gem 'roda', require: 'roda'

gem 'config'
gem 'i18n', require: 'i18n'

gem 'activesupport', require: false

gem 'dry-initializer'
gem 'dry-validation'

group :development do
  gem 'pry'
end

group :development, :test do
  gem 'rubocop', require: false
  gem 'rubocop-rspec', require: false
end

group :test do
  gem 'database_cleaner-sequel'
  gem 'factory_bot'
  gem 'rack-test'
  gem 'rspec'
end
