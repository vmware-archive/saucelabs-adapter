require 'rubygems'
require 'active_support/core_ext/object' # for .blank?

require File.join(File.dirname(__FILE__), '..', 'lib', 'saucelabs_adapter')
SELENIUM_YML_FIXTURE_FILE = File.join(File.dirname(__FILE__), 'fixtures', 'selenium.yml')


describe "SeleniumConfig" do

  context "given a saucelabs/firefix/linux configuration" do
    before do
      @selenium_config = SaucelabsAdapter::SeleniumConfig.new('stanza_saucelabs_firefox_linux', SELENIUM_YML_FIXTURE_FILE)
    end

    describe "configure_polonium" do
      before do
        @polonium_configuration = mock("Polonium::Configuration")
      end

      it "should call the appropriate configuration methods on the polonium configuration object" do
        @polonium_configuration.should_receive(:'selenium_server_host=').with("saucelabs.com")
        @polonium_configuration.should_receive(:'selenium_server_port=').with("4444")
        @polonium_configuration.should_receive(:'browser=')
        @polonium_configuration.should_receive(:'external_app_server_host=') # hostname is dynamically generated
        @polonium_configuration.should_receive(:'external_app_server_port=').with("80")

        @selenium_config.configure_polonium(@polonium_configuration)
      end
    end

    describe "configure_webrat" do
      before do
        @webrat_configuration = mock("Webrat::Configuration")
      end

      it "should call the appropriate configuration methods on the webrat configuration object" do
        @webrat_configuration.should_receive(:'selenium_server_address=').with("saucelabs.com")
        @webrat_configuration.should_receive(:'selenium_server_port=').with("4444")
        @webrat_configuration.should_receive(:'selenium_browser_key=')
        @webrat_configuration.should_receive(:'application_address=') # hostname is dynamically generated
        @webrat_configuration.should_receive(:'application_port=').with("80")

        @selenium_config.configure_webrat(@webrat_configuration)
      end
    end
  end
end
