ENV['SELENIUM_ENV'] ||= 'local'

ENV["RAILS_ENV"] = "test"
rails_root = File.dirname(__FILE__) + '/../..'
ENV['RAILS_ROOT'] = rails_root

require 'selenium/client'
require 'saucelabs_adapter'
require 'saucelabs_adapter/rspec_adapter'
require File.expand_path(rails_root + '/config/environment')

require 'rspec/rails'
require 'webrat'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

Webrat.configure do |config|
  config.mode = :selenium
  #optional:
  config.selenium_browser_key = '*chrome'
  config.selenium_server_port = 4445
#  config.application_port = 4567 # defaults to 3001. Avoid Selenium's default port, 4444
#  config.application_framework = :sinatra  # could also be :merb. Defaults to :rails
#  config.application_environment = :selenium # should equal the environment of the test runner because of database and gem dependencies. Defaults to :test.
  config.selenium_browser_startup_timeout = 10
end


RSpec.configure do |config|
  config.include Rails.application.routes.url_helpers
  config.include Webrat::Matchers
  config.include Webrat::Methods

  require "webrat/selenium/application_servers/rails"

  Dir[File.expand_path(File.join(File.dirname(__FILE__), 'support', '**', '*.rb'))].each { |f| require f }

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true
end
