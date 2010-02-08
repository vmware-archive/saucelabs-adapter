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

3. Install the python script dependencies with:

    If you don't have Python easy_install installed, download and install it:

        curl -O http://peak.telecommunity.com/dist/ez_setup.py
        sudo python ez_setup.py

    then install the Python dependencies:

        sudo easy_install httplib2 simplejson twisted pycrypto pyasn1

4. Run the saucelabs_adapter generator in your project:

        cd your_project

        script/generate saucelabs_adapter

5. Configure it.  In config/selenium.yml, replace YOUR-SAUCELABS-USERNAME and
   YOUR-SAUCELABS-ACCESS-KEY with your saucelabs.com account information.

6. If you are not using JsUnit, you can delete the following generated files:

        tests/jsunit/jsunit_test_example.rb
        lib/tasks/jsunit.rake
        jsunit stanzas from config/selenium.yml

7. Run Tests

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
        [saucelabs-adapter] Shutting down tunnel to Saucelabs...closed
        [saucelabs-adapter] done.

What it Does
------------

The saucelabs-adapter performs two functions when it detects you are running a test that will use saucelabs.com:

1. It sets up a SauceTunnel before the test run starts and tears it down after the test ends.  This happens once for the entire test run.

2. It configures the selenium client to connect to the correct address at saucelabs.com.  This happens at the start of each test.

Release Notes
=============

x.x.NEXT
--------
The gem has been reorganized to better conform with Gem best-practices.  The rakefile generator has changed.
If you are upgrading, you will need to rerun the generator and overwrite lib/tasks/saucelabs_adapter.rake,
or just change line 1 of that file to read:
        require 'saucelabs_adapter/run_utils'
