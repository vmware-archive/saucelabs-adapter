module JsunitSeleniumSupport

  def requires
    require 'run_utils'
    require "selenium/client"
    require 'lsof'
  end

  def setup_jsunit_selenium(options = {})
    requires
    @selenium_config = SeleniumConfig.new(ENV['SELENIUM_ENV'])
    start_app_server(options)
    @selenium_driver = @selenium_config.create_driver(options)
    puts "[JsunitSeleniumSupport] calling @selenium_driver.start" if options[:debug]
    @selenium_driver.start
    puts "[JsunitSeleniumSupport] @selenium_driver.start done"  if options[:debug]
  end

  def teardown_jsunit_selenium
    @selenium_driver.stop
    stop_app_server
  end

  def run_jsunit_test(jsunit_params, options = {})
    if $:.detect{ |x| x =~ /Selenium/}
      raise 'Selenium gem should not be in path! (deprecated in favor of selenium-client, which we require)'
    end

    default_jsunit_params = {
      :testPage => "/jsunit/javascripts/test-pages/suite.html",
      :autorun => "true",
      :setupPageTimeout => "60",
      :pageLoadTimeout => "60",
      :suppressCacheBuster => (@selenium_config['selenium_server_address'] == 'saucelabs.com').to_s
    }
    jsunit_params.reverse_merge!(default_jsunit_params)

    test_url = "/jsunit/javascripts/jsunit/jsunit/testRunner.html?" + jsunit_params.map { |k,v| "#{k}=#{v}" }.join("&")
    run_suite(@selenium_driver, test_url, options)
  end

  private

  def pid_file
    prepare_pid_file("#{RAILS_ROOT}/tmp/pids", "mongrel_selenium.pid")
  end

  def prepare_pid_file(file_path, pid_file_name)
    FileUtils.mkdir_p File.expand_path(file_path)
    File.expand_path("#{file_path}/#{pid_file_name}")
  end

  def local_app_server_port
    @selenium_config[:localhost_app_server_port] || @selenium_config[:application_port]
  end
  
  def start_app_server(options = {})
    stop_app_server
    puts "[JsunitSeleniumSupport] starting application server:"
    app_server_logfile_path = options[:app_server_logfile_path] || "#{RAILS_ROOT}/log/jsunit_jetty_app_server.log"
    RunUtils.run "ant -f #{RAILS_ROOT}/public/javascripts/jsunit/jsunit/build.xml start_server " +
                        "-Dport=#{local_app_server_port} " +
                        "-DcustomJsUnitJarPath=#{RAILS_ROOT}/public/javascripts/jsunit/jsunit_jar/jsunit.jar " +
                        "-DresourceBase=#{RAILS_ROOT}/public >> #{app_server_logfile_path} 2>&1 &"
  end

  def stop_app_server
    raise "oops don't know port app server is running on" unless local_app_server_port
    while Lsof.running?(local_app_server_port)
      puts "Killing app server at #{local_app_server_port}..."
      Lsof.kill(local_app_server_port)
      sleep 1
    end
  end

  def run_suite(selenium_driver, suite_path, options = {})
    default_options = {
      :timeout_in_seconds => 1200
    }
    options.reverse_merge!(default_options)

    selenium_driver.open(suite_path)

    # It would be nice if this worked, but it doesn't (it returns nil even though 'Done' is not in the element).
    # selenium.wait_for_condition(
    #   "new RegExp('Done').test(window.mainFrame.mainStatus.document.getElementById('content').innerHTML)")

    tests_completed = false
    begin_time = Time.now
    status = ""
    puts "[JsunitSeleniumSupport] Starting to poll JsUnit..." if options[:verbose]
    while (Time.now - begin_time) < options[:jsunit_suite_timeout_seconds] && !tests_completed
      sleep 5
      status = selenium_driver.js_eval("window.mainFrame.mainStatus.document.getElementById('content').innerHTML")
      status.gsub!(/^<[bB]>Status:<\/[bB]> /, '')
      # Long form: window.frames['mainFrame'].frames['mainCounts'].frames['mainCountsRuns'].document.getElementById('content').innerHTML
      runs = selenium_driver.js_eval("window.mainFrame.mainCounts.mainCountsRuns.document.getElementById('content').innerHTML").strip
      fails = selenium_driver.js_eval("window.mainFrame.mainCounts.mainCountsFailures.document.getElementById('content').innerHTML").strip
      errors = selenium_driver.js_eval("window.mainFrame.mainCounts.mainCountsErrors.document.getElementById('content').innerHTML").strip
      run_count = runs.match(/\d+$/)[0].to_i
      fail_count = fails.match(/\d+$/)[0].to_i
      error_count = errors.match(/\d+$/)[0].to_i
      puts "[JsunitSeleniumSupport] runs/fails/errors: #{run_count}/#{fail_count}/#{error_count} status: #{status}" if options[:verbose]
      if status =~ /^Done /
        tests_completed = true
      end
    end
    raise "[JsunitSeleniumSupport] Tests failed to complete after #{options[:jsunit_suite_timeout_seconds]}, status was '#{status}'" unless tests_completed

    puts "[JsunitSeleniumSupport] ********** JSUnit tests complete, Runs: #{run_count}, Fails: #{fail_count}, Errors: #{error_count} **********"

    if (fail_count + error_count > 0)
        error_messages = selenium_driver.js_eval("window.mainFrame.mainErrors.document.getElementsByName('problemsList')[0].innerHTML")
        puts "[JsunitSeleniumSupport] Error messages: #{error_messages}"
    end

    (fail_count + error_count) == 0
  end
end