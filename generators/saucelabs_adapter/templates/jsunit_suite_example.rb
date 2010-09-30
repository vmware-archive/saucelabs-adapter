require File.dirname(__FILE__) + "/../test_helper"
require "saucelabs_adapter"
require "saucelabs_adapter/jsunit_selenium_support"

class JsunitTest < ActiveSupport::TestCase
  include SaucelabsAdapter::JsunitSeleniumSupport

  def setup
    setup_jsunit_selenium # :timeout_in_seconds => 60, :app_server_logfile_path => "#{RAILS_ROOT}/log/jsunit_jetty_app_server.log"
  end

  def teardown
    teardown_jsunit_selenium
  end

  def test_javascript
    test_page = "/jsunit/javascripts/test-pages/" + (ENV['TEST'] ? "#{ENV['TEST']}.html" : "suite.html")
    assert run_jsunit_test({:testPage => test_page}, :jsunit_suite_timeout_seconds => 600, :verbose => true)
  end
end
