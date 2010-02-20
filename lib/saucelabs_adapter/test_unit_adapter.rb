if defined?(ActiveSupport)
  puts "[saucelabs-adapter] Inserting ActiveSupport::TestCase before_setup :configure_selenium hook" if ENV['SAUCELABS_ADAPTER_DEBUG']

  module ::ActiveSupport
    class TestCase
      setup :configure_selenium # 'before_setup' callback from ActiveSupport::TestCase

      def configure_selenium
        puts "[saucelabs-adapter] configuring selenium..." if ENV['SAUCELABS_ADAPTER_DEBUG'] && ENV['SAUCELABS_ADAPTER_DEBUG'].to_i >= 2
        selenium_config = SaucelabsAdapter::SeleniumConfig.new(ENV['SELENIUM_ENV'])
        if defined?(Polonium)
          polonium_config = Polonium::Configuration.instance
          selenium_config.configure_polonium(polonium_config)
        elsif defined?(Webrat)
          webrat_config = Webrat.configuration
          selenium_config.configure_webrat(webrat_config)
        end
      end
    end
  end
end

if defined?(Test)
  puts "[saucelabs-adapter] Inserting Test::Unit::UI::Console::TestRunner attach_to_mediator tunnel start hook" if ENV['SAUCELABS_ADAPTER_DEBUG']

  class Test::Unit::UI::Console::TestRunner

    private

    def attach_to_mediator_with_sauce_tunnel
      attach_to_mediator_without_sauce_tunnel
      @selenium_config = SaucelabsAdapter::SeleniumConfig.new(ENV['SELENIUM_ENV'])
      if @selenium_config.start_sauce_tunnel?
        @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::STARTED, &method(:setup_tunnel))
        @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::FINISHED, &method(:teardown_tunnel))
      end
    end

    alias_method_chain :attach_to_mediator, :sauce_tunnel unless private_method_defined?(:attach_to_mediator_without_sauce_tunnel)

    def setup_tunnel(suite_name)
      @tunnel = SaucelabsAdapter::SauceTunnel.new(@selenium_config)
    end

    def teardown_tunnel(suite_name)
      @tunnel.shutdown
    end
  end
end