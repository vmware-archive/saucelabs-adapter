if defined?(Spec::Runner)

  module Spec
    module Runner
      class Configuration
        attr_accessor :saucelabs_tunnel
      end
    end
  end
  Spec::Runner.configure do |config|
    config.before :all do
      selenium_config = SaucelabsAdapter::SeleniumConfig.new(ENV['SELENIUM_ENV'])
      if selenium_config.start_tunnel? and config.saucelabs_tunnel.nil?
        config.saucelabs_tunnel = SaucelabsAdapter::Tunnel.factory(selenium_config)
        config.saucelabs_tunnel.start_tunnel
      end
      webrat_config = Webrat.configuration
      selenium_config.configure_webrat(webrat_config)
    end

    at_exit do
      config.saucelabs_tunnel.shutdown if config.saucelabs_tunnel
    end
  end
end
