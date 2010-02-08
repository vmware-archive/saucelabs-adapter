puts "[saucelabs-adapter] gem is loading..." if ENV['SAUCELABS_ADAPTER_DEBUG']
require 'saucelabs_adapter/selenium_config'
require 'saucelabs_adapter/sauce_tunnel'
require 'saucelabs_adapter/test_unit_adapter'
require 'saucelabs_adapter/jsunit_selenium_support'