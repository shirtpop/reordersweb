source "https://rubygems.org"

# Rails framework
gem "rails", "~> 8.0.2"

# Database
gem "pg", "~> 1.1"

# Asset pipeline
gem "propshaft"
gem "importmap-rails"
gem "tailwindcss-rails"
gem "image_processing", "~> 1.2"

# JavaScript frameworks
gem "stimulus-rails"
gem "turbo-rails"

# Web server
gem "puma", ">= 5.0"
gem "thruster", require: false

# Authentication & authorization
gem "devise"
gem "bcrypt", "~> 3.1.7"

# UI components & styling
gem "flowbite", "~> 3.1"
gem "view_component"

# Pagination
gem "pagy"

# Background jobs processing
gem "solid_queue"
gem "mission_control-jobs"

# API building
gem "jbuilder"

# Google services integration
gem "googleauth"
gem "google-apis-drive_v3"

# Error monitoring & notifications
gem "exception_notification"
gem "slack-notifier"

# Performance optimization
gem "bootsnap", require: false

# Platform-specific dependencies
gem "tzinfo-data", platforms: %i[windows jruby]

# Development & testing tools
group :development, :test do
  gem "byebug", platforms: [ :mri, :mingw, :x64_mingw ]
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"
end

# Development tools
group :development do
  gem "web-console"
end

# Deployment
group :development do
  gem "capistrano", require: false
  gem "capistrano-rbenv", require: false
  gem "capistrano-rails", require: false
  gem "capistrano-bundler", require: false
  gem "capistrano3-puma", "6.2.0", require: false
  gem "ed25519", require: false
  gem "bcrypt_pbkdf", require: false
end
