include SaucelabsAdapter::Utilities

module RSpec
  module Core
    class Configuration
      attr_accessor :saucelabs_tunnel
    end
  end
end

selenium_config = SaucelabsAdapter::SeleniumConfig.new(ENV['SELENIUM_ENV'])

RSpec.configure do |config|
  config.before :suite do
    if selenium_config.start_tunnel? and config.saucelabs_tunnel.nil?
      config.saucelabs_tunnel = SaucelabsAdapter::Tunnel.factory(selenium_config)
      config.saucelabs_tunnel.start_tunnel
    end
  end

  config.before :each do
    ENV['SAUCELABS_JOB_NAME'] = "#{::Rails.root.to_s.split('/').last} - #{config.saucelabs_tunnel.se_config.application_address}"

    if defined?(Webrat)
      webrat_config = Webrat.configuration
      selenium_config.configure_webrat(webrat_config)
    else
      puts "[saucelabs_adapter] Starting browser session" if ENV['SAUCELABS_ADAPTER_DEBUG']
      @browser = selenium_config.create_driver
      @browser.start_new_browser_session
    end
  end

  config.after :each do
    if defined?(@browser)
      puts "[saucelabs_adapter] Ending browser session" if ENV['SAUCELABS_ADAPTER_DEBUG']
      @browser.close_current_browser_session
    end
  end

  config.after :suite do
    config.saucelabs_tunnel.shutdown if config.saucelabs_tunnel
  end
end
