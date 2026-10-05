# frozen_string_literal: true

source 'https://rubygems.org'

gem 'hanami', '~> 2.0'
gem 'hanami-controller', '~> 2.0'
gem 'hanami-router', '~> 2.0'
gem 'hanami-validations', '~> 2.0'

gem 'dry-types', '~> 1.0', '>= 1.6.1'
gem 'puma'
gem 'rake'

gem 'pg', '~> 1.4', '>= 1.4.5'
gem 'rom', '~> 5.3'
gem 'rom-sql', '~> 3.6', '>= 3.6.1'

group :development, :test do
  gem 'dotenv'
  gem 'rubocop', '~> 1.40'
  gem 'rubocop-performance', '~> 1.15', '>= 1.15.1'
  gem 'rubocop-rake', '~> 0.6.0'
  gem 'rubocop-rspec', '~> 2.15'
end

group :cli, :development do
  gem 'hanami-reloader'
end

group :cli, :development, :test do
  gem 'hanami-rspec'
end

group :development do
  gem 'guard-puma', '~> 0.8'
end

group :test do
  gem 'database_cleaner-sequel', '~> 2.0', '>= 2.0.2'
  gem 'rack-test'
end
