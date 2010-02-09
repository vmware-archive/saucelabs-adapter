Saucelabs-Adapter
=================

Saucelabs-adapter provides the glue to connect Rails Selenium tests to saucelabs.com.

Currently it only supports tests written using Polonium and JSUnit.

Quick Start
-----------

1. Prerequisites:

    You must be able to run selenium tests locally using test/selenium/selenium_suite.rb

2. Install the gem:

        gem install saucelabs-adapter --source gems.pivotallabs.com

3. Run the saucelabs_adapter generator in your project:

        cd your_project

        script/generate saucelabs_adapter

4. Configure it.  In config/selenium.yml, replace YOUR-SAUCELABS-USERNAME and
   YOUR-SAUCELABS-ACCESS-KEY with your saucelabs.com account information.

5. If you are not using JsUnit, you can delete the following generated files:

        tests/jsunit/jsunit_test_example.rb
        lib/tasks/jsunit.rake
        jsunit stanzas from config/selenium.yml

6. Run Tests

    To run Selenium Test::Unit tests locally:

        rake selenium:local

    To run Selenium Test::Unit tests using saucelabs.com:

        rake selenium:sauce

    To run JsUnit tests locally:

        rake jsunit:selenium_rc:local

    To run JsUnit tests using saucelabs.com:

        rake jsunit:selenium_rc:sauce

What You Should See
-------------------

When running rake selenium:sauce, intermixed with your test output you should see the following lines:

        Loaded suite test/selenium/selenium_suite
        [saucelabs-adapter] Setting up tunnel from Saucelabs (yourhostname-12345.com:80) to localhost:4000
        [saucelabs-adapter] Tunnel ID 717909c571b8319dc5ae708b689fd7f5 for yourhostname-12345.com is up.
        Started
        ....................
        [saucelabs-adapter] Shutting down tunnel to Saucelabs...
        [saucelabs-adapter] done.

What it Does
------------

The saucelabs-adapter performs two functions when it detects you are running a test that will use saucelabs.com:

1. It sets up a SauceTunnel before the test run starts and tears it down after the test ends.  This happens once for the entire test run.

2. It configures the selenium client to connect to the correct address at saucelabs.com.  This happens at the start of each test.

CHANGES
=======

0.7.0
-----
- The gem has been reorganized to better conform with Gem best-practices.

- The rakefile generator has changed.  If you are upgrading, you will need to rerun the generator and overwrite lib/tasks/saucelabs_adapter.rake,
or just change line 1 of that file to read:

        require 'saucelabs_adapter/run_utils'

- The selenium.yml syntax has changed to break out all the saucelabs info into separate lines, and the tunnel method is now explicitly stated:

    - Old:
            selenium_browser_key: '{"username": "YOUR-SAUCELABS-USERNAME", "access-key": "YOUR-SAUCELABS-ACCESS-KEY", "os": "Linux", "browser": "firefox", "browser-version": "3."}'
            #
            localhost_app_server_port: "4000"
            tunnel_startup_timeout: 240

    - New:
            saucelabs_username: "YOUR-SAUCELABS-USERNAME"
            saucelabs_access_key: "YOUR-SAUCELABS-ACCESS-KEY"
            saucelabs_browser_os: "Linux"
            saucelabs_browser: "firefox"
            saucelabs_browser_version: "3."
            #
            tunnel_method: :saucetunnel
            tunnel_to_localhost_port: 4000
            tunnel_startup_timeout: 240
            
- The dependency on Python has been removed.
