
# This generator bootstraps a Rails project for use with RSpec
class SaucelabsAdapterGenerator < Rails::Generator::Base
  DEFAULT_SHEBANG = File.join(Config::CONFIG['bindir'],
                              Config::CONFIG['ruby_install_name'])

  def initialize(runtime_args, runtime_options = {})
      puts <<-HELPFUL_INSTRUCTIONS

After running this generator:

1) Go edit config/selenium.yml and add your SauceLabs API credentials
2) Add this to your selenium_helper.rb:

  require 'saucelabs-adapter'

HELPFUL_INSTRUCTIONS
    super
  end

  def manifest
    record do |m|
      m.directory 'lib/tasks'
      m.file      'saucelabs_adapter.rake',        'lib/tasks/saucelabs_adapter.rake'
      m.file      'selenium.yml',                  'config/selenium.yml'
    end
  end

protected

  def banner
    "Usage: #{$0} saucelabs_adapter"
  end

end
