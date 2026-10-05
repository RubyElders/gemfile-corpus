source 'https://rubygems.org'

gem 'rake'
gem 'hanami',       '~> 1.3'
gem 'hanami-model', git: "https://github.com/hanami/model.git", require: false

gem 'pg'

gem 'vonage'

gem 'dotenv'

group :development do
  # Code reloading
  # See: https://guides.hanamirb.org/projects/code-reloading
  gem 'shotgun', platforms: :ruby
  gem 'hanami-webconsole'
end


group :test do
  gem 'rspec'
  gem 'capybara'
end

group :production do
  # gem 'puma'
end
