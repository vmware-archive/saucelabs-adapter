require 'run_utils'

namespace :jsunit do
  namespace :selenium_rc do
    desc "Runs JsUnit tests locally using configuration 'local' in config/selenium.yml (selenium server must already be started)"
    task :local => [:local_jsunit_env, :suite]

    desc "Run JsUnit tests at saucelabs.com (using configuration 'saucelabs' in config/selenium.yml)"
    task :sauce => [:sauce_jsunit_env, :suite]

    desc "Run JsUnit tests at saucelabs.com for all supported browsers"
    task :sauce_all => [:sauce_jsunit_all_env, :suite]

    desc "Run Selenium tests using configuration SELENIUM_ENV (from config/selenium.yml)"
    task :custom => [:check_selenium_env_is_set, :suite]

    task :local_jsunit_env do
      ENV['SELENIUM_ENV'] = 'local_jsunit'
    end

    task :sauce_jsunit_env do
      ENV['SELENIUM_ENV'] = 'saucelabs_jsunit'
    end

    task :sauce_jsunit_all_env do
      ENV['SELENIUM_ENV'] = "saucelabs_jsunit_firefox,saucelabs_jsunit_ie,saucelabs_jsunit_chrome,saucelabs_jsunit_safari"
    end

    task :check_selenium_env_is_set do
      raise "SELENIUM_ENV must be set" unless ENV['SELENIUM_ENV']
    end

    task :suite do
      unless (File.exists?("test/jsunit/jsunit_suite.rb"))
        raise "test/jsunit/jsunit_suite.rb not found, bailing.\nPlease create a script that will run your jsunit tests."
      end
      ENV['RUNNING_POLONIUM'] = 'false'

      # TODO: This multi-suite support is a hack and slow, but it's the easiest way to support it without major refactoring to saucelabs_adapter
      env = ENV['SELENIUM_ENV']
      if env =~ /,/
        begin
          envs = env.split(',')
          envs.each do |single_env|
            ENV['SELENIUM_ENV'] = single_env
            run_suite
          end
        ensure
          # make sure we reset it to avoid confusion
          ENV['SELENIUM_ENV'] = env
        end
      else
        run_suite
      end
    end

    def run_suite
      success = RunUtils.run "ruby test/jsunit/jsunit_suite.rb"
      raise "Jsunit suite run for #{ENV['SELENIUM_ENV']} environment failed." unless success
    end
  end
end
