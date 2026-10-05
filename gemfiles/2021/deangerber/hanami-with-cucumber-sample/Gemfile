source 'https://rubygems.org'

gem 'bundler'
gem 'rake'
gem 'hanami',       '~> 0.8'
gem 'hanami-model', '~> 0.6'

gem 'pg'

group :development do
  gem 'shotgun'
end

group :test do
end

group :development, :test do
  gem 'dotenv', '~> 2.0'
  gem 'cucumber', require: false
  gem 'rspec'
  gem 'capybara'
end

group :production do
  # gem 'puma'
end
