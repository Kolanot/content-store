source 'https://rubygems.org'

gem 'rails', '4.1.4'
gem 'rails-api', '0.2.1'

gem 'mongoid', '4.0.0'

gem 'logstasher', '0.5.0'
gem 'airbrake', '3.1.15'

gem 'unicorn', '4.8.2'

gem 'plek', '~> 1.7.0'

if ENV['GDS_API_ADAPTERS_DEV']
  gem 'gds-api-adapters', :path => '../gds-api-adapters'
else
  gem 'gds-api-adapters', '~> 11.0.0'
end

group :development, :test do
  gem 'rspec-rails', '2.14.2'
  gem 'database_cleaner', '1.2.0'
  gem 'factory_girl', '4.4.0'
  gem 'webmock', '~> 1.18.0', :require => false
  gem 'timecop', '0.7.1'

  gem 'simplecov', '0.8.2', :require => false
  gem 'simplecov-rcov', '0.2.3', :require => false
  gem 'ci_reporter', '1.9.2'
end
