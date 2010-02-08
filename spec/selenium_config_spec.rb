require 'rubygems'
require 'active_support/core_ext/object' # for .blank?

require File.join(File.dirname(__FILE__), '..', 'lib', 'saucelabs_adapter')
SELENIUM_YML_FIXTURE_FILE = File.join(File.dirname(__FILE__), 'fixtures', 'selenium.yml')

# Doing this to capture args because I seriously doubt we can mock out .new()
module Selenium
  module Client
    class Driver
      attr_reader :args
      def initialize(args)
        @args = args
      end
    end
  end
end

describe "SeleniumConfig" do

  context "given a saucelabs/firefix/linux configuration" do
    before do
      @selenium_config = SaucelabsAdapter::SeleniumConfig.new('stanza_saucelabs_firefox_linux', SELENIUM_YML_FIXTURE_FILE)
    end

    describe "selenium_browser_key" do
      before do
        @browser_data = JSON.parse(@selenium_config[:selenium_browser_key])
      end

      {
        'username'        => "YOUR-SAUCELABS-USERNAME",
        'access-key'      => "YOUR-SAUCELABS-ACCESS-KEY",
        'os'              => "Linux",
        'browser'         => "firefox",
        'browser-version' => "3."
      }.each do |browser_data_key, browser_data_value|
        it "should contain a #{browser_data_key} of #{browser_data_value}" do
          @browser_data[browser_data_key].should == browser_data_value
        end
      end

      it "should contain a job_name of our hostname" do
        @browser_data['job-name'].should == Socket.gethostname
      end
    end

    describe "#configure_polonium" do
      before do
        @polonium_configuration = mock("Polonium::Configuration")
      end

      it "should call the appropriate configuration methods on the polonium configuration object" do
        @polonium_configuration.should_receive(:'selenium_server_host=').with("saucelabs.com")
        @polonium_configuration.should_receive(:'selenium_server_port=').with("4444")
        @polonium_configuration.should_receive(:'browser=').with(@selenium_config[:selenium_browser_key])
        @polonium_configuration.should_receive(:'external_app_server_host=').with(@selenium_config[:application_address])
        @polonium_configuration.should_receive(:'external_app_server_port=').with("80")

        @selenium_config.configure_polonium(@polonium_configuration)
      end
    end

    describe "#configure_webrat" do
      before do
        @webrat_configuration = mock("Webrat::Configuration")
      end

      it "should call the appropriate configuration methods on the webrat configuration object" do
        @webrat_configuration.should_receive(:'selenium_server_address=').with("saucelabs.com")
        @webrat_configuration.should_receive(:'selenium_server_port=').with("4444")
        @webrat_configuration.should_receive(:'selenium_browser_key=').with(@selenium_config[:selenium_browser_key])
        @webrat_configuration.should_receive(:'application_address=').with(@selenium_config[:application_address])
        @webrat_configuration.should_receive(:'application_port=').with("80")

        @selenium_config.configure_webrat(@webrat_configuration)
      end
    end

    describe "#create_driver" do
      before do
        @driver = @selenium_config.create_driver
      end

      it "should call Driver.new with the correct arguments" do
        @driver.args[:host].should == 'saucelabs.com'
        @driver.args[:port].should == '4444'
        @driver.args[:browser].should_not be_blank
        @driver.args[:url].should == "http://#{@selenium_config[:application_address]}:80"
        @driver.args[:timeout_in_seconds].should == 600        
      end
    end
  end
end
