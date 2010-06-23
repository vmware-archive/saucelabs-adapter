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
        elsif defined?(Webrat)
          webrat_config = Webrat.configuration
          selenium_config.configure_webrat(webrat_config)
        end
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
      if @selenium_config.kill_mongrel_after_suite?
        @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::FINISHED, &method(:kill_mongrel_if_needed))
      end
    end

    alias_method_chain :attach_to_mediator, :sauce_tunnel unless private_method_defined?(:attach_to_mediator_without_sauce_tunnel)

    def setup_tunnel(suite_name)
      @tunnel = SaucelabsAdapter::Tunnel.factory(@selenium_config)
      @tunnel.start_tunnel
    end

    def teardown_tunnel(suite_name)
      @tunnel.shutdown
    end

    def kill_mongrel_if_needed(suite_name)
      mongrel_pid_file = File.join(RAILS_ROOT, "tmp", "pids", "mongrel_selenium.pid")
      if File.exists?(mongrel_pid_file)
        pid = File.read(mongrel_pid_file).to_i
        say "Killing mongrel at #{pid}"
        Process.kill("KILL", pid)
      end
      if File.exists?(mongrel_pid_file)
        FileUtils.rm(mongrel_pid_file)
      end
    end
  end
end