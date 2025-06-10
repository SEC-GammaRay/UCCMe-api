# frozen_string_literal: true

source 'https://rubygems.org'
ruby File.read('.ruby-version').strip

# web API
gem 'logger', '~>1.0'
gem 'puma', '~>6.0'
gem 'roda', '~>3.0'

# Configuration
gem 'figaro', '~>1.2'
gem 'rake'

# securirty
gem 'http'
gem 'rbnacl', '~> 7.1'
gem 'base64'

# Database
gem 'hirb'
gem 'sequel', '~>5.55'
group :production do
  gem 'pg'
end

# debugging
gem 'pry' # necessary for rake console
gem 'reline'

# development
group :development do
  # debugging
  gem 'rerun'

  # quality
  gem 'rubocop'
  gem 'rubocop-minitest'
  gem 'rubocop-performance'
  gem 'rubocop-rake'
  gem 'rubocop-sequel'

  # audit
  gem 'bundler-audit'
end

group :development, :test do
  # api testing
  gem 'rack', '>= 3.1.16'
  gem 'rack-test'

  # database
  gem 'sequel-seed'
  gem 'sqlite3', '~> 2.6'
end

# testing
group :test do
  gem 'minitest'
  gem 'minitest-rg'
end

# mail
gem 'activesupport'
gem 'erb'
gem 'mailjet'

# aws
gem 'aws-sdk-s3'
