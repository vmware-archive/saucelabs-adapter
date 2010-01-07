class SeleniumConfig
  attr_reader :local_port

  def initialize(config_name = nil, selenium_yml = nil, local_port = 4000)
    if defined?(@@configuration_name) && @@configuration_name != config_name
      @@configuration == nil
    end
    @@configuration_name = config_name
    @selenium_yml = selenium_yml || File.join(RAILS_ROOT, 'config', 'selenium.yml')
    @local_port = local_port
  end

  def configuration
    @@configuration ||= read_configuration(@@configuration_name)
  end

  def [](attribute)
    case attribute
    when :username, 'username', :'access-key', 'access-key', :os, 'os', :browser, 'browser', :'browser-version', 'browser_version'
      ::JSON.parse(configuration['selenium_browser_key'])[attribute.to_s]
    else
      configuration[attribute]
    end
  end

  # Takes a Webrat::Configuration and configures it
  def configure_webrat(webrat_configuration_object)
    configuration.each do |method, value|
      webrat_configuration_object.send("#{method}=", value)
    end
  end

  # Map Webrat::Configuration to Polonium::Configuration methods
  WEBRAT_TO_POLONIUM_CONFIG_METHODS = {
    'application_framework'   => 'app_server_engine',
    'selenium_server_address' => 'selenium_server_host',
    'selenium_browser_key'    => 'browser',
    'application_address'     => 'external_app_server_host',
    'application_port'        => 'external_app_server_port'
  } unless defined?(WEBRAT_TO_POLONIUM_CONFIG_METHODS)

  # Takes a Polonium::Configuration and configures it
  def configure_polonium(polonium_configuration_object)
    configuration.each do |method, value|
      config_method = WEBRAT_TO_POLONIUM_CONFIG_METHODS[method] || method
      polonium_configuration_object.send("#{config_method}=", value)
    end
  end

  private

  def read_configuration(configuration_name)
    selenium_configs = YAML.load_file(@selenium_yml)
    configuration = selenium_configs[configuration_name]
    raise "Stanza '#{configuration_name}' not found" unless configuration

    if configuration['selenium_server_address'] == 'saucelabs.com'
      # We are using Sauce Labs and therefore the Sauce Tunnel.
      # We need to use a masquerade hostname on the EC2 end of the tunnel that will be unique within the scope of
      # this account (e.g. pivotallabs).  Therefore we mint a fairly unique hostname here.
      hostname = Socket.gethostname.split(".").first
      configuration['application_address'] = "#{hostname}-#{Process.pid}.com"
    end
    configuration
  rescue Exception => e
    puts "[saucelabs-adapter] Disabled. (Couldn't read config '#{configuration_name}' in #{@selenium_yml}: #{e.message})"
    {}
  end
end
