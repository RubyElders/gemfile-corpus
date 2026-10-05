# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.1'

gem 'contentful_model', '~> 1.3'
gem 'erubi', '~> 1.9'
gem 'puma', '~> 5.0'
gem 'rack-unreloader', '~> 1.7'
gem 'refrigerator', '~> 1.2'
gem 'roda', '~> 3.36'
gem 'tilt', '~> 2.0', '>= 2.0.10'

group :test do
  gem 'capybara'
  gem 'minitest', '~> 5.14', '>= 5.14.2'
  gem 'minitest-global_expectations'
  gem 'minitest-hooks', '~> 1.5'
  gem 'pry'
  gem 'warning'
end

group :development do
  gem 'pry'
  gem 'rubocop'
  gem 'rubocop-rspec'
end
