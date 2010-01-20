require 'run_utils'

namespace :jsunit do
  namespace :selenium_rc do
    desc "Runs JsUnit tests locally using configuration 'local' in config/selenium.yml (selenium server must already be started)"
    task :local => ['selenium:local_env', :suite]

    desc "Run JsUnit tests at saucelabs.com (using configuration 'saucelabs' in config/selenium.yml)"
    task :sauce => [:sauce_jsunit_env, :suite]

    desc "Run Selenium tests using configuration SELENIUM_ENV (from config/selenium.yml)"
    task :custom => [:check_selenium_env_is_set, :suite]

    task :sauce_jsunit_env do
      ENV['SELENIUM_ENV'] = 'saucelabs_jsunit'
    end

    task :check_selenium_env_is_set do
      raise "SELENIUM_ENV must be set" unless ENV['SELENIUM_ENV']
    end

    task :suite do
      if (File.exists?("test/jsunit/jsunit_suite.rb"))
        RunUtils.run "ruby test/jsunit/jsunit_suite.rb"
      else
        puts "test/jsunit/jsunit_suite.rb not found, bailing.\nPlease create a script that will run your jsunit tests."
        exit 1
      end
    end
  end
end
