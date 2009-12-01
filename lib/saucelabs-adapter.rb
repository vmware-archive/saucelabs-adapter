require 'selenium_config'
require 'sauce_tunnel'

module Polonium
  class NewTestCase < ActiveSupport::TestCase
    def setup
      raise "Cannot use transactional fixtures if ActiveRecord concurrency is turned on (which is required for Selenium tests to work)." if self.class.use_transactional_fixtures
      selenium_config = SeleniumConfig.new(ENV['SELENIUM_ENV'])
      selenium_config.configure_polonium(configuration)
      @selenium_driver = configuration.driver
    end
  end
end

class Test::Unit::UI::Console::TestRunner

  def attach_to_mediator_with_sauce_tunnel
    attach_to_mediator_without_sauce_tunnel
    @selenium_config = SeleniumConfig.new(ENV['SELENIUM_ENV'])
    if @selenium_config['selenium_server_address'] == 'saucelabs.com'
      @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::STARTED, &method(:setup_tunnel))
      @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::FINISHED, &method(:teardown_tunnel))
    end
  end

  alias_method_chain :attach_to_mediator, :sauce_tunnel unless private_method_defined?(:attach_to_mediator_without_sauce_tunnel)

  def setup_tunnel(suite_name)
    puts "Opening tunnel to Saucelabs"
    @tunnel = SauceTunnel.new(@selenium_config)
  end

  def teardown_tunnel(suite_name)
    puts "Shutting down tunnel to Saucelabs"
    @tunnel.shutdown
  end
end