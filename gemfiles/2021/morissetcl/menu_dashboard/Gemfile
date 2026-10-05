source 'https://rubygems.org'

gem 'rake'
gem 'hanami',       '~> 1.3'
gem 'hanami-model', '~> 1.3'
gem 'pg'
#messae queue
gem 'redis-rails'
gem 'redis-namespace'
gem 'sneakers'

gem 'hanami-assets'

group :development do
  # Code reloading
  # See: https://guides.hanamirb.org/projects/code-reloading
  gem 'shotgun', platforms: :ruby
  gem 'hanami-webconsole'
end

group :test, :development do
  gem 'dotenv', '~> 2.4'
end

group :test do
  gem 'rspec'
  gem 'capybara'
  gem 'bunny-mock', '~> 1.2'
  gem "fakeredis", :require => "fakeredis/rspec"
end

group :production do
  # gem 'puma'
end
