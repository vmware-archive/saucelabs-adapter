
# This generator bootstraps a Rails project for use with RSpec
class SaucelabsAdapterGenerator < Rails::Generator::Base
  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])

  def initialize(runtime_args, runtime_options = {})
    puts <<-HELPFUL_INSTRUCTIONS

    The saucelabs_adapter generator installs glue to connect your Selenium tests to saucelabs.com

    Read the README.markdown at http://github.com/pivotal/saucelabs-adapter for
    detailed instructions on various usage scenarios.

    HELPFUL_INSTRUCTIONS
    super
  end

  def manifest
    record do |m|
      m.directory 'lib/tasks'
      m.file      'saucelabs_adapter.rake',        'lib/tasks/saucelabs_adapter.rake'
      m.file      'selenium.yml',                  'config/selenium.yml'
      m.directory 'test/selenium'
      m.file      'sample_webrat_test.rb',         'test/selenium/sample_webrat_test.rb'
      m.file      'selenium_suite.rb',             'test/selenium/selenium_suite.rb'
      if options[:jsunit]
        m.file      'jsunit.rake',                   'lib/tasks/jsunit.rake'
        m.directory 'test/jsunit'
        m.file      'jsunit_suite_example.rb',       'test/jsunit/jsunit_suite_example.rb'
      end
    end
  end

protected

  def banner
    "Usage: #{$0} saucelabs_adapter [options]"
  end

  def add_options!(opt)
    opt.separator ''
    opt.separator 'Options:'
    opt.on('--jsunit', 'Also install Saucelabs support for JsUnit') do |value|
      options[:jsunit] = true
    end
  end
end
