require 'selenium_config'
require 'sauce_tunnel'
require 'jsunit_selenium_support'

if defined?(ActiveSupport)

  module ::ActiveSupport
    class TestCase
      setup :configure_selenium # 'before_setup' callback from ActiveSupport::TestCase

      def configure_selenium
        selenium_config = SeleniumConfig.new(ENV['SELENIUM_ENV'])
        if defined?(Polonium)
          puts "[saucelabs-adapter] configuring Polonium"
          polonium_config = Polonium::Configuration.instance
          selenium_config.configure_polonium(polonium_config)
        elsif defined?(Webrat)
          raise "Webrat not yet supported"
          puts "[saucelabs-adapter] configuring Webrat"
          webrat_config = Webrat.configuration
          selenium_config.configure_webrat(webrat_config)
        end
      end
    end
  end
end

if defined?(Test)

  class Test::Unit::UI::Console::TestRunner

    private

    def attach_to_mediator_with_sauce_tunnel
      attach_to_mediator_without_sauce_tunnel
      @selenium_config = SeleniumConfig.new(ENV['SELENIUM_ENV'])
      if @selenium_config.start_tunnel?
        @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::STARTED, &method(:setup_tunnel))
        @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::FINISHED, &method(:teardown_tunnel))
      end
    end

    alias_method_chain :attach_to_mediator, :sauce_tunnel unless private_method_defined?(:attach_to_mediator_without_sauce_tunnel)

    def setup_tunnel(suite_name)
      @tunnel = SauceTunnel.new(@selenium_config)
    end

    def teardown_tunnel(suite_name)
      @tunnel.shutdown
    end
  end
end