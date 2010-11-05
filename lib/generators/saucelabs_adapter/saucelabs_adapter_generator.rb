class SaucelabsAdapterGenerator < Rails::Generators::Base
  source_root File.expand_path('../templates', __FILE__)

  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])

  def initialize(runtime_args, runtime_options = {}, config = {})
    puts <<-HELPFUL_INSTRUCTIONS

    The saucelabs_adapter generator installs glue to connect your Selenium tests to saucelabs.com

    After running this generator:

    1) Go edit config/selenium.yml and add your SauceLabs API credentials
    2) Add this to your selenium_helper.rb:

      require 'saucelabs_adapter'

    HELPFUL_INSTRUCTIONS
    super
  end

  def manifest
    copy_file 'saucelabs_adapter.rake',        'lib/tasks/saucelabs_adapter.rake'
    copy_file 'selenium.yml',                  'config/selenium.yml'

    empty_directory 'spec/selenium'
    empty_directory 'spec/selenium/support'
    create_file 'spec/selenium/support/.gitkeep'
    copy_file      'selenium_spec_helper.rb',             'spec/selenium/selenium_spec_helper.rb'
    copy_file      'sample_selenium_spec.rb',             'spec/selenium/sample_selenium_spec.rb'
    copy_file      'webrat_overrides.rb',                 'spec/selenium/support/webrat_overrides.rb'
  end

protected
  def banner
    "Usage: #{$0} saucelabs_adapter [options]"
  end
end
