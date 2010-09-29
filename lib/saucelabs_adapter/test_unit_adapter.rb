if defined?(ActiveSupport::TestCase) && ActiveSupport::TestCase.respond_to?(:setup)
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
        elsif defined?(Webrat) && selenium_config.test_framework.to_sym == :webrat
          webrat_config = Webrat.configuration
          selenium_config.configure_webrat(webrat_config)
        else
          puts "[saucelabs-adapter] Starting browser session"
          @browser = selenium_config.create_driver
          @browser.start_new_browser_session
        end
      end

      def teardown
        if defined?(@browser)
          puts "[saucelabs-adapter] Ending browser session"
          @browser.close_current_browser_session
        end
        super
      end
    end
  end
end

if defined?(Test::Unit::UI::Console::TestRunner)
  puts "[saucelabs-adapter] Inserting Test::Unit::UI::Console::TestRunner attach_to_mediator tunnel start hook" if ENV['SAUCELABS_ADAPTER_DEBUG']

  class Test::Unit::UI::Console::TestRunner
    include SaucelabsAdapter::Utilities

    private

    def attach_to_mediator_with_sauce_tunnel
      attach_to_mediator_without_sauce_tunnel
      @selenium_config = SaucelabsAdapter::SeleniumConfig.new(ENV['SELENIUM_ENV'])
      if @selenium_config.start_tunnel?
        @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::STARTED, &method(:setup_tunnel))
        @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::FINISHED, &method(:teardown_tunnel))
      end

      if selenium_config.start_server.to_sym == :true
        @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::STARTED, &method(:start_mongrel))
      end

      @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::FINISHED, &method(:kill_mongrel_if_needed))
    end

    alias_method_chain :attach_to_mediator, :sauce_tunnel unless private_method_defined?(:attach_to_mediator_without_sauce_tunnel)
  end
end
