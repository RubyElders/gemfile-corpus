source 'https://rubygems.org'

gem 'rake'
gem 'hanami',       '~> 1.1'
gem 'hanami-model', '~> 1.1'
gem 'pry'

gem 'pg'
gem 'hanami-shrine'
gem 'hanami-pagination'
gem 'hanami-bootstrap'
gem 'jquery-hanami'
gem 'hanami-octicons'
gem 'nokogiri'
gem 'loofah'
gem 'isbn_extractor', github: 'mbobin/isbn_extractor'

group :development do
  # Code reloading
  # See: http://hanamirb.org/guides/projects/code-reloading
  gem 'shotgun'
end

group :test, :development do
  gem 'dotenv', '~> 2.0'
end

group :test do
  gem 'rspec-hanami'
  gem 'capybara'
end

group :production do
  # gem 'puma'
end
